import {MutableRefObject, useEffect, useRef} from "react";
import {noop} from "../utils/misc";


type NuiKeyboardHandler = (event: KeyboardEvent) => void;


export const useNuiKeyboard = <T = any>(
    key: string,
    handler: NuiKeyboardHandler
  ) => {
    const savedHandler = useRef<NuiKeyboardHandler>(() => {});
  
    // Make sure we handle for a reactive handler
    useEffect(() => {
      savedHandler.current = handler;
    }, [handler]);
  
    useEffect(() => {
      const eventListener = (event: KeyboardEvent) => {
        if (event.key !== key) return;
        if (event.repeat) return;

        const target = event.target as HTMLElement | null;
        const isEditable =
          target &&
          (target.tagName === 'INPUT' ||
            target.tagName === 'TEXTAREA' ||
            target.isContentEditable);
        if (isEditable) return;

        if (savedHandler.current) {
          // @ts-ignore
          savedHandler.current(event);
        }
      };
  
      window.addEventListener("keydown", eventListener);
      return () => window.removeEventListener("keydown", eventListener);
    }, [key]);
  };