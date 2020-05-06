import parsePattern, { Pattern } from "./parse-pattern";
import isBackspace from "../is-backspace";
import type { Selection } from "../input-selection";

// TODO better name
export type Formatted = {
  value: string;
  selection: Selection;
};

export interface SimulateDeleteOptions extends Formatted {
  event: KeyboardEvent;
}

class PatternFormatter {
  pattern: Pattern[]; // TODO

  constructor(pattern: string) {
    // TODO ask talk-javascript about why we can't use setPattern here instead
    this.pattern = parsePattern(pattern);
  }

  // TODO we can possibly remove this since it's not used outside the class
  setPattern(pattern: string) {
    this.pattern = parsePattern(pattern);
  }

  format(options: Formatted): Formatted {
    const originalString = options.value;
    let originalStringIndex = 0;
    let formattedString = "";
    const selection = {
      start: options.selection.start,
      end: options.selection.end,
    };

    for (let i = 0; i < this.pattern.length; i++) {
      const patternChar = this.pattern[i];
      let inputChar = originalString[originalStringIndex];

      if (originalStringIndex > originalString.length) {
        break;
      }

      if (typeof patternChar.value === "string") {
        if (inputChar != null || formattedString.length === patternChar.index) {
          formattedString += patternChar.value;
          if (patternChar.index <= selection.start) {
            selection.start++;
          }
          if (patternChar.index <= selection.end) {
            selection.end++;
          }
        }
      } else {
        // User input char
        for (
          ;
          originalStringIndex < originalString.length;
          originalStringIndex++
        ) {
          inputChar = originalString[originalStringIndex];

          if (patternChar.value.test(inputChar)) {
            formattedString += inputChar;
            originalStringIndex++;
            break;
          } else {
            if (patternChar.index <= selection.start) {
              selection.start--;
            }
            if (patternChar.index <= selection.end) {
              selection.end--;
            }
          }
        }
      }
    }

    return {
      value: formattedString,
      selection: selection,
    };
  }

  unformat(options: Formatted) {
    let start = options.selection.start;
    let end = options.selection.end;
    let unformattedString = "";

    for (let i = 0; i < this.pattern.length; i++) {
      const patternChar = this.pattern[i];

      if (
        typeof patternChar.value !== "string" &&
        options.value[i] != null &&
        patternChar.value.test(options.value[i])
      ) {
        unformattedString += options.value[i];
        continue;
      }

      if (patternChar.value !== options.value[patternChar.index]) {
        continue;
      }
      if (patternChar.index < options.selection.start) {
        start--;
      }
      if (patternChar.index < options.selection.end) {
        end--;
      }
    }

    return {
      selection: {
        start: start,
        end: end,
      },
      value: unformattedString,
    };
  }

  simulateDeletion(options: SimulateDeleteOptions) {
    let deletionStart, deletionEnd;
    const state = this.unformat(options);
    const value = state.value;
    const selection = state.selection;
    const delta = Math.abs(state.selection.end - state.selection.start);

    if (delta) {
      deletionStart = selection.start;
      deletionEnd = selection.end;
    } else if (isBackspace(options.event)) {
      deletionStart = Math.max(0, selection.start - 1);
      deletionEnd = selection.start;
    } else {
      // Handle forward delete
      deletionStart = selection.start;
      deletionEnd = Math.min(value.length, selection.start + 1);
    }

    return {
      selection: {
        start: deletionStart,
        end: deletionStart,
      },
      value: value.substr(0, deletionStart) + value.substr(deletionEnd),
    };
  }
}

export default PatternFormatter;
