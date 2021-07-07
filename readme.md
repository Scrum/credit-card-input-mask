# credit-card-input-mask

> forked from braintree/restricted-input

Allow restricted character sets in `input` elements.

## Install

```bash
$ npm install --save credit-card-input-mask
```

## Usage

```javascript
import CreditCardInputMask from "credit-card-input-mask";

const formattedCreditCardInput = new CreditCardInputMask({
  element: document.querySelector("#credit-card"),
  pattern: "{{9999}} {{9999}} {{9999}} {{9999}}",
});
```

> [Demo](https://scrum.github.io/credit-card-input-mask/)

## Patterns

Patterns are a mixture of [`Placeholder`](#placeholder)s and [`PermaChar`](#permachar)s.

### Placeholder

A `Placeholder` is the part of the pattern that accepts user input based on some restrictions. A placeholder is defined in the pattern using two open curly brackets, the placeholder, followed by two closing curly brackets e.g. `{{Abc123}}`.

The patterns a `Placeholder` can be are:

- a single alpha character that matches the alpha regex `/[A-Za-z]/`. e.g. `{{C}}` will match one alpha character.
- a single digit that matches the digit regex `/[0-9]/`. e.g. `{{3}}` will match one digit.
- a `*` character that matches `/./`. e.g. `{{*}}` will match the next character.

### PermaChar

A `PermaChar` is the part of the pattern that is automatically inserted. `PermaChar`s are defined in the pattern as any characters other than `Placeholder`s.

### Example patterns

Some example patterns with behavior are listed:

- `12{{3}}`
  - Inserts `12`.
  - Waits for a single digit from the user.
- `{{A}}BC`
  - Waits for a single alpha from the user.
  - Inserts `BC`.
- `${{*2L}}E`
  - Inserts `$`.
  - Waits for any single character input from the user.
  - Waits for a single digit from the user.
  - Waits for a single alpha from the user.
  - Inserts `E`.

## Paste Event

If an input is changed via a paste event, you may want to adjust the pattern before input formatting occurs. In this case, pass an `onPasteEvent` callback:

```js
const formattedCreditCardInput = new RestrictedInput({
  element: document.querySelector('#credit-card'),
  pattern: '{{9999}} {{9999}} {{9999}} {{9999}}',
  onPasteEvent: function (payload) {
    var value = payload.unformattedInputValue;

    if (requiresAmexPattern(value)) {
      formattedCreditCardInput.setPattern('{{9999}} {{999999}} {{99999}}')
    } else {
      formattedCreditCardInput.setPattern('{{9999}} {{9999}} {{9999}} {{9999}}')
    }
  })
});
```

## API

### options

| Key          | Type                                        | Description                                                                                                              |
| ------------ | ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| element      | `HTMLInputElement` or `HTMLTextAreaElement` | A valid reference to an `input` or `textarea` DOM node                                                                   |
| pattern      | `String`                                    | Pattern describing the allowed character set you wish for entry into corresponding field. See [Patterns](#patterns).     |
| onPasteEvent | `Function` (optional)                       | A callback function to inspect the unformatted value of the input during a paste event. See [Paste Event](#paste-event). |

## Related

- [restricted-input](https://github.com/braintree/restricted-input) - Allow restricted character sets in `input` elements.
