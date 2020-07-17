import React, { createContext, useMemo, useEffect, useState } from 'react';
import PropTypes from 'prop-types';

const AcuantContext = createContext({
  isReady: false,
  isError: false,
  credentials: null,
  endpoint: null,
});

function AcuantContextProvider({ sdkSrc, credentials, endpoint, children }) {
  const [isReady, setIsReady] = useState(false);
  const [isError, setIsError] = useState(false);
  const value = useMemo(() => ({ isReady, isError, endpoint, credentials }), [
    isReady,
    isError,
    endpoint,
    credentials,
  ]);

  let acuantLoaded = false;

  useEffect(() => {
    // Acuant SDK expects this global to be assigned at the time the script is
    // loaded, which is why the script element is manually appended to the DOM.
    const originalOnAcuantSdkLoaded = window.onAcuantSdkLoaded;
    window.onAcuantSdkLoaded = () => {
      window.AcuantJavascriptWebSdk.initialize(credentials, endpoint, {
        onSuccess: () => {
          acuantLoaded = true;
          setIsReady(true);
        },
        onFail: () => {
          acuantLoaded = true;
          setIsError(true);
        },
      });
    };

    const script = document.createElement('script');
    script.async = true;
    script.src = sdkSrc;

    const acuantCheck = () => {
      setTimeout(() => {
        console.log('acuantLoaded', acuantLoaded);
        if (!acuantLoaded) {
          console.log('Reloading acuant...');
          document.body.removeChild(script);
          document.body.appendChild(script);
          acuantCheck();
        }
      }, 3000);
    };

    acuantCheck();
    document.body.appendChild(script);

    return () => {
      window.onAcuantSdkLoaded = originalOnAcuantSdkLoaded;
      document.body.removeChild(script);
    };
  }, []);

  return (
    <AcuantContext.Provider value={value}>{children}</AcuantContext.Provider>
  );
}

AcuantContextProvider.propTypes = {
  sdkSrc: PropTypes.string,
  credentials: PropTypes.string,
  endpoint: PropTypes.string,
  children: PropTypes.node,
};

AcuantContextProvider.defaultProps = {
  sdkSrc: '/AcuantJavascriptWebSdk.min.js',
  credentials: null,
  endpoint: null,
  children: null,
};

export const Provider = AcuantContextProvider;

export default AcuantContext;
