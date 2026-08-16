import {MutableRefObject, useEffect, useRef} from "react";
import {noop} from "../utils/misc";


type NuiHandlerSignature<T> = (data: T) => void;


export const useNuiKeyboard = <T = any>(
    key: string,
    handler: (data: T) => void
  ) => {
    const savedHandler: MutableRefObject<NuiHandlerSignature<T>> = useRef(noop);
  
    // Make sure we handle for a reactive handler
    useEffect(() => {
      savedHandler.current = handler;
    }, [handler]);
  
    useEffect(() => {
      const eventListener = (event: KeyboardEvent) => {
        if (event.key == key) {
          if (savedHandler.current) {
            // @ts-ignore
            savedHandler.current(event);
          }
        }
      };
  
      window.addEventListener("keydown", eventListener);
      return () => window.removeEventListener("keydown", eventListener);
    }, [key]);
  };