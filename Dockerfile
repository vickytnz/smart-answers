FROM ruby:2.1.5-onbuild
CMD ["./startup.sh"]
EXPOSE 3010
ENV GOVUK_ASSET_ROOT="https://assets.publishing.service.gov.uk" \
    GOVUK_WEBSITE_ROOT="https://www.gov.uk" \
    GOVUK_APP_DOMAIN="assets.publishing.service.gov.uk" \
    PLEK_SERVICE_STATIC_URI="https://assets.publishing.service.gov.uk" \
    PLEK_SERVICE_CONTENTAPI_URI="https://www.gov.uk/api"
