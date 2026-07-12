# Invite-only beta release checklist

AO3Chat's beta is private by default. Readers join from personal invitations, all discussions require login, and only staff can issue invites.

## Deploy

From the DigitalOcean host, rebuild the application and apply the AO3Chat defaults:

```bash
cd /var/discourse
./launcher rebuild app
./launcher enter app
su discourse -c 'bundle exec rake ao3_fanfic_forum:configure'
su discourse -c 'bundle exec rake ao3_fanfic_forum:beta_audit'
exit
```

The configure task enforces two-factor authentication for staff. Set up an authenticator and save backup codes when prompted.

## Before inviting readers

- Confirm the beta audit reports only `PASS` results.
- Send a test invitation from the staff invite page and complete the full join, approval, login, password reset, and logout flow in a private browser window.
- Confirm SMTP delivery, SPF, DKIM, and DMARC alignment with the active email provider.
- Run a manual backup, download it, and verify DigitalOcean droplet backups are enabled.
- Confirm the private fandom room category is invisible to a normal reader and visible to a supporter-group test account.
- Confirm staff accounts use unique passwords and two-factor authentication.
- Review the privacy policy, terms, guidelines, contact address, and incident response contacts.

## Invite policy

Create invitations only from staff accounts. Use one redemption per invite, a 14-day expiry, and do not post invitation links publicly. Revoke unused invitations if they are forwarded or exposed.

## Release gate

Do not open the beta when the audit fails, email delivery is unreliable, a backup has not been tested, or a normal reader can access a private room.
