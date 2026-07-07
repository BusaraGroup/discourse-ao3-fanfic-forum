import { ajax } from "discourse/lib/ajax";
import { withPluginApi } from "discourse/lib/plugin-api";

const AUTH_FORM_SELECTOR = "[data-ao3-auth-form]";

function discoursePath(url) {
  const parsed = new URL(url, window.location.origin);

  return `${parsed.pathname}${parsed.search}`;
}

function timezone() {
  return Intl.DateTimeFormat().resolvedOptions().timeZone;
}

function reverse(value) {
  return value.split("").reverse().join("");
}

function formValue(form, name) {
  return form.querySelector(`[name="${name}"]`)?.value?.trim() || "";
}

function messageElement(form) {
  return form.querySelector("[data-ao3-auth-message]");
}

function setMessage(form, message, type = "error") {
  const element = messageElement(form);

  if (!element) {
    return;
  }

  element.textContent = message || form.dataset.errorMessage;
  element.hidden = false;
  element.classList.toggle("is-success", type === "success");
  element.classList.toggle("is-error", type !== "success");
}

function clearMessage(form) {
  const element = messageElement(form);

  if (!element) {
    return;
  }

  element.textContent = "";
  element.hidden = true;
  element.classList.remove("is-success", "is-error");
}

function setBusy(form, busy) {
  const button = form.querySelector("button[type='submit']");

  if (!button) {
    return;
  }

  if (!button.dataset.readyLabel) {
    button.dataset.readyLabel = button.textContent.trim();
  }

  button.disabled = busy;
  button.textContent = busy ? form.dataset.busyLabel : button.dataset.readyLabel;
}

function errorMessage(error, fallback) {
  const payload = error?.jqXHR?.responseJSON || error?.responseJSON || error;

  if (payload?.message) {
    return payload.message;
  }

  if (payload?.error) {
    return payload.error;
  }

  if (payload?.errors) {
    return Object.values(payload.errors).flat().join(" ");
  }

  return fallback;
}

function revealSecondFactor(form) {
  const wrapper = form.querySelector("[data-ao3-auth-second-factor]");
  const input = form.querySelector("[name='second_factor_token']");

  if (wrapper) {
    wrapper.hidden = false;
  }

  input?.focus();
}

function submitStaticLogin(username, password, redirect, loginUrl) {
  const form = document.createElement("form");
  form.method = "post";
  form.action = loginUrl;
  form.hidden = true;

  [
    ["username", username],
    ["password", password],
    ["redirect", redirect],
  ].forEach(([name, value]) => {
    const input = document.createElement("input");
    input.type = "hidden";
    input.name = name;
    input.value = value;
    form.append(input);
  });

  document.body.append(form);
  form.submit();
}

async function handleLogin(form) {
  clearMessage(form);
  setBusy(form, true);

  const data = {
    login: formValue(form, "login"),
    password: formValue(form, "password"),
    timezone: timezone(),
  };
  const secondFactorToken = formValue(form, "second_factor_token");

  if (secondFactorToken) {
    data.second_factor_token = secondFactorToken;
    data.second_factor_method = formValue(form, "second_factor_method") || "1";
  }

  try {
    const result = await ajax(discoursePath(form.action), {
      type: "POST",
      data,
    });

    if (result?.error) {
      if (result.totp_enabled || result.backup_enabled || result.backup_codes_enabled) {
        revealSecondFactor(form);
        setMessage(form, form.dataset.twoFactorMessage);
      } else if (result.security_key_enabled) {
        setMessage(form, form.dataset.securityKeyMessage);
      } else {
        setMessage(form, result.error);
      }

      setBusy(form, false);
      return;
    }

    submitStaticLogin(
      data.login,
      data.password,
      form.dataset.successUrl || "/",
      form.dataset.staticLoginUrl || "/login"
    );
  } catch (error) {
    setMessage(form, errorMessage(error, form.dataset.errorMessage));
    setBusy(form, false);
  }
}

async function handleSignup(form) {
  clearMessage(form);
  setBusy(form, true);

  try {
    const honeypot = await ajax("/session/hp.json");
    const data = {
      email: formValue(form, "email"),
      username: formValue(form, "username"),
      name: formValue(form, "name"),
      password: formValue(form, "password"),
      password_confirmation: honeypot.value,
      challenge: reverse(honeypot.challenge),
      timezone: timezone(),
    };
    const result = await ajax(discoursePath(form.action), {
      type: "POST",
      data,
    });

    if (result?.success) {
      if (result.active) {
        submitStaticLogin(
          data.username,
          data.password,
          form.dataset.successUrl || "/",
          form.dataset.staticLoginUrl || "/login"
        );
      } else {
        setMessage(form, result.message, "success");
        form.reset();
        setBusy(form, false);
      }

      return;
    }

    setMessage(form, result?.message || form.dataset.errorMessage);
    setBusy(form, false);
  } catch (error) {
    setMessage(form, errorMessage(error, form.dataset.errorMessage));
    setBusy(form, false);
  }
}

function bindAuthForm(form) {
  if (form.dataset.ao3AuthBound) {
    return;
  }

  form.dataset.ao3AuthBound = "true";
  form.addEventListener("submit", (event) => {
    event.preventDefault();

    if (form.dataset.ao3AuthForm === "signup") {
      handleSignup(form);
    } else {
      handleLogin(form);
    }
  });
}

function initializeAuthForms() {
  document.querySelectorAll(AUTH_FORM_SELECTOR).forEach(bindAuthForm);
}

function initializeAuthFormsWhenReady() {
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initializeAuthForms, { once: true });
  } else {
    initializeAuthForms();
  }
}

export default {
  name: "ao3-fanfic-forum",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");

    if (!siteSettings.ao3_fanfic_enabled) {
      return;
    }

    withPluginApi((api) => {
      api.addTrackedTopicProperties("ao3_fanfic");
      api.serializeOnCreate(
        "topic_custom_fields",
        "ao3Fanfic.topicCustomFields"
      );
      api.serializeToDraft("ao3_fanfic_draft", "ao3Fanfic");

      api.modifyClass(
        "model:composer",
        (Superclass) =>
          class extends Superclass {
            editPost(opts) {
              const shouldSaveAo3Metadata = this.editingFirstPost;
              const topic = this.topic;
              const topicId = topic?.id;
              const fields = this.ao3Fanfic?.topicCustomFields;

              return super.editPost(opts).then((result) => {
                if (!shouldSaveAo3Metadata || !topicId || !fields) {
                  return result;
                }

                return ajax(`/ao3-fanfic/topics/${topicId}/metadata.json`, {
                  type: "PUT",
                  data: JSON.stringify({ topic_custom_fields: fields }),
                  contentType: "application/json",
                }).then((payload) => {
                  topic.set("ao3_fanfic", payload.ao3_fanfic);
                  return result;
                });
              });
            }
          }
      );

      initializeAuthForms();
      api.onPageChange(initializeAuthForms);
    });

    initializeAuthFormsWhenReady();
  },
};
