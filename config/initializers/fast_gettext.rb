# frozen_string_literal: true

# UI texts: locale/<locale>/app.po, update them with bin/rake gettext:find
FastGettext.add_text_domain 'app', path: Rails.root.join('locale'), type: :po, ignore_fuzzy: true, report_warning: false
FastGettext.default_available_locales = %w[en de]
FastGettext.default_text_domain = 'app'
