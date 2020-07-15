# Global constants used by the SAML IdP
module Saml
  module Idp
    module Constants
      LOA1_AUTHN_CONTEXT_CLASSREF = 'http://idmanagement.gov/ns/assurance/loa/1'.freeze
      LOA3_AUTHN_CONTEXT_CLASSREF = 'http://idmanagement.gov/ns/assurance/loa/3'.freeze

      IAL1_AUTHN_CONTEXT_CLASSREF = 'http://idmanagement.gov/ns/assurance/ial/1'.freeze
      IAL2_AUTHN_CONTEXT_CLASSREF = 'http://idmanagement.gov/ns/assurance/ial/2'.freeze
      IAL2_STRICT_AUTHN_CONTEXT_CLASSREF = 'http://idmanagement.gov/ns/assurance/ial/2?strict=true'.freeze
      IALMAX_AUTHN_CONTEXT_CLASSREF = 'http://idmanagement.gov/ns/assurance/ial/0'.freeze

      AAL2_AUTHN_CONTEXT_CLASSREF = 'http://idmanagement.gov/ns/assurance/aal/2'.freeze
      AAL3_AUTHN_CONTEXT_CLASSREF = 'http://idmanagement.gov/ns/assurance/aal/3'.freeze

      ISSUERS_WITH_EMAIL_NAMEID_FORMAT = Figaro.env.issuers_with_email_nameid_format.split(',').
                                               freeze
      NAME_ID_FORMAT_PERSISTENT = 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'.freeze
      NAME_ID_FORMAT_EMAIL = 'urn:oasis:names:tc:SAML:2.0:nameid-format:emailAddress'.freeze

      REQUESTED_ATTRIBUTES_CLASSREF = 'http://idmanagement.gov/ns/requested_attributes?ReqAttr='.freeze

      VALID_AUTHN_CONTEXTS = JSON.parse(Figaro.env.valid_authn_contexts).freeze
      IAL2_AUTHN_CONTEXTS = [IAL2_AUTHN_CONTEXT_CLASSREF, LOA3_AUTHN_CONTEXT_CLASSREF].freeze

      AUTHN_CONTEXT_CLASSREF_TO_IAL = {
        LOA1_AUTHN_CONTEXT_CLASSREF => Identity::IAL1,
        LOA3_AUTHN_CONTEXT_CLASSREF => Identity::IAL2,
        IAL1_AUTHN_CONTEXT_CLASSREF => Identity::IAL1,
        IAL2_AUTHN_CONTEXT_CLASSREF => Identity::IAL2,
        IAL2_STRICT_AUTHN_CONTEXT_CLASSREF => Identity::IAL2_STRICT,
        IALMAX_AUTHN_CONTEXT_CLASSREF => Identity::IAL_MAX,
      }.freeze

      AUTHN_CONTEXT_CLASSREF_TO_AAL = {
        AAL2_AUTHN_CONTEXT_CLASSREF => Authorization::AAL2,
        AAL3_AUTHN_CONTEXT_CLASSREF => Authorization::AAL3,
      }.freeze
    end
  end
end
