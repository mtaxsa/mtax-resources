import {MutableRefObject, useEffect, useRef} from "react";
import {noop} from "../utils/misc";


type NuiHandlerSignature = (event: KeyboardEvent) => void;


export const useNuiKeyboard = (
    key: string,
    handler: (event: KeyboardEvent) => void
  ) => {
    const savedHandler: MutableRefObject<NuiHandlerSignature> = useRef(noop);

    // Make sure we handle for a reactive handler
    useEffect(() => {
      savedHandler.current = handler;
    }, [handler]);

    useEffect(() => {
      const eventListener = (event: KeyboardEvent) => {
        if (event.key == key) {
          if (savedHandler.current) {
            savedHandler.current(event);
          }
        }
      };
  
      window.addEventListener("keydown", eventListener);
      return () => window.removeEventListener("keydown", eventListener);
    }, [key]);
  };