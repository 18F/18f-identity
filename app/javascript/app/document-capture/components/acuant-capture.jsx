import React, { useContext, useState } from 'react';
import PropTypes from 'prop-types';
import AcuantContext from '../context/acuant';
import AcuantCaptureCanvas from './acuant-capture-canvas';
import FileInput from './file-input';
import FullScreen from './full-screen';
import Button from './button';
import useI18n from '../hooks/use-i18n';
import DeviceContext from '../context/device';
import DataURLFile from '../models/data-url-file';

function AcuantCapture({ label, hint, bannerText, value, onChange, className }) {
  const { isReady, isError, isCameraSupported } = useContext(AcuantContext);
  const [isCapturing, setIsCapturing] = useState(false);
  const { isMobile } = useContext(DeviceContext);
  const { t } = useI18n();
  const hasCapture = !isError && (isReady ? isCameraSupported : isMobile);

  let startCaptureIfSupported;
  if (hasCapture) {
    startCaptureIfSupported = (event) => {
      event.preventDefault();
      setIsCapturing(true);
    };
  }

  return (
    <div className={className}>
      {isCapturing && (
        <FullScreen onRequestClose={() => setIsCapturing(false)}>
          <AcuantCaptureCanvas
            onImageCaptureSuccess={(nextCapture) => {
              onChange(nextCapture.image.data);
              setIsCapturing(false);
            }}
            onImageCaptureFailure={() => setIsCapturing(false)}
          />
        </FullScreen>
      )}
      <FileInput
        label={label}
        hint={hint}
        bannerText={bannerText}
        accept={['image/*']}
        value={value}
        onClick={startCaptureIfSupported}
        onChange={onChange}
      />
      {hasCapture && (
        <Button
          isSecondary={!value}
          isUnstyled={!!value}
          onClick={() => setIsCapturing(true)}
          className="display-block margin-top-2"
        >
          {t(value ? 'doc_auth.buttons.take_picture_retry' : 'doc_auth.buttons.take_picture')}
        </Button>
      )}
    </div>
  );
}

AcuantCapture.propTypes = {
  label: PropTypes.string.isRequired,
  hint: PropTypes.string,
  bannerText: PropTypes.string,
  value: PropTypes.instanceOf(DataURLFile),
  onChange: PropTypes.func,
  className: PropTypes.string,
};

AcuantCapture.defaultProps = {
  hint: null,
  value: null,
  bannerText: null,
  onChange: () => {},
  className: null,
};

export default AcuantCapture;
