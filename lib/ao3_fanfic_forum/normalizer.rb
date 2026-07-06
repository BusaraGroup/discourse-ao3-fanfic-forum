# frozen_string_literal: true

module Ao3FanficForum
  module Normalizer
    MAX_TERMS = 30

    module_function

    def text(value, max_length: nil)
      value = value.to_s.unicode_normalize(:nfkc).strip.gsub(/\s+/, " ")
      max_length ? value[0, max_length] : value
    end

    def boolean(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end

    def integer(value)
      return nil if value.blank?

      value.to_i
    end

    def date_time(value)
      return nil if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def list(value)
      values =
        case value
        when Array
          value
        when String
          parse_string_list(value)
        else
          []
        end

      values
        .map { |item| text(item, max_length: 120) }
        .reject(&:blank?)
        .uniq { |item| key(item) }
        .first(MAX_TERMS)
    end

    # Accepts only http(s) URLs. Scheme-less values ("archiveofourown.org/...")
    # are prefixed with https://; anything else (javascript:, data:, ftp:,
    # unparseable input) normalizes to nil so it can never render as a link.
    def url(value, max_length: nil)
      value = text(value, max_length: max_length)
      return nil if value.blank?

      candidate = value.match?(%r{\A[a-z][a-z0-9+\-.]*://}i) ? value : "https://#{value}"

      begin
        uri = URI.parse(candidate)
      rescue URI::Error
        return nil
      end

      return nil if !uri.is_a?(URI::HTTP) || uri.host.blank?

      candidate
    end

    def key(value)
      text(value).downcase.gsub(/[^\p{Alnum}]+/, "-").gsub(/\A-+|-+\z/, "")
    end

    def parse_string_list(value)
      stripped = value.to_s.strip
      return [] if stripped.blank?

      if stripped.start_with?("[")
        parsed = JSON.parse(stripped)
        return parsed if parsed.is_a?(Array)
      end

      stripped.split(/[,\n|]/)
    rescue JSON::ParserError
      stripped.split(/[,\n|]/)
    end
  end
end
