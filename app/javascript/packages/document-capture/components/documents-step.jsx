import { useContext } from 'react';
import BlockLink from './block-link';
import AcuantCapture from './acuant-capture';
import FormErrorMessage, { CameraAccessDeclinedError } from './form-error-message';
import useI18n from '../hooks/use-i18n';
import DeviceContext from '../context/device';
import ServiceProviderContext from '../context/service-provider';
import withBackgroundEncryptedUpload from '../higher-order/with-background-encrypted-upload';

/**
 * @typedef {'front'|'back'} DocumentSide
 */

/**
 * @typedef DocumentsStepValue
 *
 * @prop {Blob|string|null|undefined} front Front image value.
 * @prop {Blob|string|null|undefined} back Back image value.
 * @prop {string=} front_image_metadata Front image metadata.
 * @prop {string=} back_image_metadata Back image metadata.
 */

/**
 * Sides of document to present as file input.
 *
 * @type {DocumentSide[]}
 */
const DOCUMENT_SIDES = ['front', 'back'];

/**
 * @return {Boolean} whether or not the value is valid for the document step
 */
function documentsStepValidator(value = {}) {
  return DOCUMENT_SIDES.every((side) => !!value[side]);
}

/**
 * @param {import('./form-steps').FormStepComponentProps<DocumentsStepValue>} props Props object.
 */
function DocumentsStep({
  value = {},
  onChange = () => {},
  errors = [],
  onError = () => {},
  registerField = () => undefined,
}) {
  const { t, formatHTML } = useI18n();
  const { isMobile } = useContext(DeviceContext);
  const serviceProvider = useContext(ServiceProviderContext);

  return (
    <>
      {isMobile && <p>{t('doc_auth.info.document_capture_intro_acknowledgment')}</p>}
      <p className="margin-bottom-0">{t('doc_auth.tips.document_capture_header_text')}</p>
      <ul>
        <li>{t('doc_auth.tips.document_capture_id_text1')}</li>
        <li>{t('doc_auth.tips.document_capture_id_text2')}</li>
        <li>{t('doc_auth.tips.document_capture_id_text3')}</li>
        {!isMobile && <li>{t('doc_auth.tips.document_capture_id_text4')}</li>}
      </ul>
      {serviceProvider.name && (
        <BlockLink url={serviceProvider.getFailureToProofURL('documents_having_trouble')}>
          {formatHTML(t('doc_auth.info.get_help_at_sp_html', { sp_name: serviceProvider.name }), {
            strong: 'strong',
          })}
        </BlockLink>
      )}
      {DOCUMENT_SIDES.map((side) => {
        const error = errors.find(({ field }) => field === side)?.error;

        return (
          <AcuantCapture
            key={side}
            ref={registerField(side, { isRequired: true })}
            /* i18n-tasks-use t('doc_auth.headings.document_capture_back') */
            /* i18n-tasks-use t('doc_auth.headings.document_capture_front') */
            label={t(`doc_auth.headings.document_capture_${side}`)}
            /* i18n-tasks-use t('doc_auth.headings.back') */
            /* i18n-tasks-use t('doc_auth.headings.front') */
            bannerText={t(`doc_auth.headings.${side}`)}
            value={value[side]}
            onChange={(nextValue, metadata) =>
              onChange({
                [side]: nextValue,
                [`${side}_image_metadata`]: JSON.stringify(metadata),
              })
            }
            onCameraAccessDeclined={() => {
              onError(new CameraAccessDeclinedError(), { field: side });
              onError(new CameraAccessDeclinedError());
            }}
            errorMessage={error ? <FormErrorMessage error={error} /> : undefined}
            name={side}
          />
        );
      })}
    </>
  );
}

export default withBackgroundEncryptedUpload(DocumentsStep);

export { documentsStepValidator };
