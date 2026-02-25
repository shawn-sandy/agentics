# WCAG Accessibility Testing Guide

This document provides guidance on automated and manual accessibility testing tools and approaches.

## Table of Contents

1. [Automated Testing Tools](#automated-testing-tools)
2. [Browser Extensions](#browser-extensions)
3. [Component Testing](#component-testing)
4. [Manual Testing Checklist](#manual-testing-checklist)
5. [Color Contrast Tools](#color-contrast-tools)

---

## Automated Testing Tools

### axe-core (Recommended)

**What it tests:** WCAG 2.1 Level A and AA issues, including semantic HTML, ARIA, color contrast, forms, and more.

**Installation:**

```bash
npm install --save-dev @axe-core/react
# or
npm install --save-dev axe-core
```

**React Integration:**

```tsx
// Add to your index.tsx or App.tsx (development only)
if (process.env.NODE_ENV !== 'production') {
  import('@axe-core/react').then((axe) => {
    axe.default(React, ReactDOM, 1000);
  });
}
```

**Jest/Testing Library:**

```bash
npm install --save-dev jest-axe
```

```tsx
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

test('should have no accessibility violations', async () => {
  const { container } = render(<MyComponent />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

**Playwright/Cypress Integration:**

```bash
npm install --save-dev @axe-core/playwright
# or
npm install --save-dev cypress-axe
```

```ts
// Playwright
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('should not have accessibility violations', async ({ page }) => {
  await page.goto('http://localhost:3000');
  
  const accessibilityScanResults = await new AxeBuilder({ page }).analyze();
  
  expect(accessibilityScanResults.violations).toEqual([]);
});
```

```ts
// Cypress
import 'cypress-axe';

describe('Accessibility tests', () => {
  beforeEach(() => {
    cy.visit('/');
    cy.injectAxe();
  });

  it('Has no detectable accessibility violations', () => {
    cy.checkA11y();
  });
});
```

---

### eslint-plugin-jsx-a11y

**What it tests:** JSX accessibility rules during development.

**Installation:**

```bash
npm install --save-dev eslint-plugin-jsx-a11y
```

**Configuration (.eslintrc.json):**

```json
{
  "extends": [
    "plugin:jsx-a11y/recommended"
  ],
  "plugins": [
    "jsx-a11y"
  ],
  "rules": {
    "jsx-a11y/alt-text": "error",
    "jsx-a11y/aria-props": "error",
    "jsx-a11y/aria-proptypes": "error",
    "jsx-a11y/aria-unsupported-elements": "error",
    "jsx-a11y/click-events-have-key-events": "error",
    "jsx-a11y/heading-has-content": "error",
    "jsx-a11y/html-has-lang": "error",
    "jsx-a11y/img-redundant-alt": "error",
    "jsx-a11y/label-has-associated-control": "error",
    "jsx-a11y/no-autofocus": "warn",
    "jsx-a11y/no-static-element-interactions": "error",
    "jsx-a11y/role-has-required-aria-props": "error",
    "jsx-a11y/role-supports-aria-props": "error"
  }
}
```

---

### pa11y

**What it tests:** Command-line accessibility testing using HTML CodeSniffer.

**Installation:**

```bash
npm install --save-dev pa11y
```

**Usage:**

```bash
# Test a single URL
npx pa11y http://localhost:3000

# Test with WCAG 2.1 AA standard
npx pa11y --standard WCAG2AA http://localhost:3000

# Test multiple URLs
npx pa11y-ci
```

**pa11y-ci configuration (`.pa11yci.json`):**

```json
{
  "defaults": {
    "standard": "WCAG2AA",
    "timeout": 10000,
    "wait": 500
  },
  "urls": [
    "http://localhost:3000",
    "http://localhost:3000/about",
    "http://localhost:3000/contact"
  ]
}
```

---

### Lighthouse CI

**What it tests:** Accessibility score as part of Lighthouse audits.

**Installation:**

```bash
npm install --save-dev @lhci/cli
```

**Configuration (`lighthouserc.json`):**

```json
{
  "ci": {
    "collect": {
      "url": ["http://localhost:3000"],
      "numberOfRuns": 3
    },
    "assert": {
      "assertions": {
        "categories:accessibility": ["error", {"minScore": 0.9}],
        "aria-allowed-attr": "error",
        "aria-required-attr": "error",
        "aria-valid-attr": "error",
        "button-name": "error",
        "color-contrast": "error",
        "document-title": "error",
        "html-has-lang": "error",
        "image-alt": "error",
        "label": "error",
        "link-name": "error"
      }
    }
  }
}
```

**Run:**

```bash
npx lhci autorun
```

---

### Accessibility Insights

**What it tests:** Comprehensive automated and guided manual testing.

**Installation:**
- Desktop App: https://accessibilityinsights.io/downloads/
- Browser Extension: Install from Chrome/Edge Web Store

**Features:**
- FastPass: Automated checks for common issues
- Assessment: Guided manual testing for WCAG 2.1 Level AA
- Ad hoc tools: Color contrast, landmarks, headings, tab stops

---

## Browser Extensions

### axe DevTools

**Browser:** Chrome, Firefox, Edge

**Features:**
- Automated accessibility testing
- Element inspection
- Guided remediation
- Intelligent Guided Tests for comprehensive coverage

**How to use:**
1. Open DevTools (F12)
2. Navigate to "axe DevTools" tab
3. Click "Scan ALL of my page"
4. Review violations and recommendations

---

### WAVE

**Browser:** Chrome, Firefox, Edge

**Features:**
- Visual feedback about accessibility
- Icons show errors, warnings, and features
- Color contrast analyzer
- Structure/order visualization

**How to use:**
1. Click WAVE extension icon
2. Review errors (red), alerts (yellow), and features (green)
3. Use tabs: Summary, Details, Reference, Structure, Contrast

---

### Accessibility Insights for Web

**Browser:** Chrome, Edge

**Features:**
- FastPass automated checks
- Assessment guided tests
- Ad hoc tools (Color, Headings, Landmarks, Tab stops)

**How to use:**
1. Click extension icon
2. Choose "FastPass" for quick automated scan
3. Choose "Assessment" for comprehensive manual testing
4. Use "Ad hoc tools" for specific checks

---

### Screen Reader Testing

**NVDA (Windows - Free):**
- Download: https://www.nvaccess.org/download/
- Basic commands:
  - Insert + Down Arrow: Read all
  - Insert + T: Read title
  - H/Shift+H: Navigate headings
  - K/Shift+K: Navigate links
  - F/Shift+F: Navigate form fields

**JAWS (Windows - Paid):**
- Download: https://www.freedomscientific.com/products/software/jaws/
- Similar commands to NVDA
- Free trial available

**VoiceOver (macOS - Built-in):**
- Enable: Cmd + F5
- Basic commands:
  - VO + A: Read all
  - VO + Right/Left Arrow: Navigate
  - VO + U: Open rotor (headings, links, landmarks)
  - VO + Shift + Down Arrow: Interact with groups

**TalkBack (Android - Built-in):**
- Enable: Settings > Accessibility > TalkBack
- Swipe right/left to navigate
- Double tap to activate

**VoiceOver (iOS - Built-in):**
- Enable: Settings > Accessibility > VoiceOver
- Swipe right/left to navigate
- Double tap to activate

---

## Component Testing

### Testing Library Best Practices

Use accessible queries in priority order:

```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

test('form is accessible', async () => {
  const user = userEvent.setup();
  render(<MyForm />);
  
  // ✅ Good - queries by accessible name
  const nameInput = screen.getByLabelText('Name');
  const submitButton = screen.getByRole('button', { name: 'Submit' });
  
  // ❌ Bad - queries by test IDs or classes
  // const nameInput = screen.getByTestId('name-input');
  // const submitButton = screen.getByClassName('submit-btn');
  
  await user.type(nameInput, 'John Doe');
  await user.click(submitButton);
});
```

**Query Priority:**
1. `getByRole` - Most accessible
2. `getByLabelText` - For form elements
3. `getByPlaceholderText` - Only if no label
4. `getByText` - For non-interactive elements
5. `getByDisplayValue` - Current form value
6. `getByAltText` - For images
7. `getByTitle` - Last resort
8. `getByTestId` - Avoid for accessibility testing

### Example Comprehensive Component Test

```tsx
import { render, screen } from '@testing-library/react';
import { axe } from 'jest-axe';
import userEvent from '@testing-library/user-event';

describe('LoginForm', () => {
  test('has no accessibility violations', async () => {
    const { container } = render(<LoginForm />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  test('is keyboard navigable', async () => {
    const user = userEvent.setup();
    render(<LoginForm />);
    
    // Tab through form
    await user.tab();
    expect(screen.getByLabelText('Email')).toHaveFocus();
    
    await user.tab();
    expect(screen.getByLabelText('Password')).toHaveFocus();
    
    await user.tab();
    expect(screen.getByRole('button', { name: 'Log In' })).toHaveFocus();
  });

  test('shows error messages accessibly', async () => {
    const user = userEvent.setup();
    render(<LoginForm />);
    
    const submitButton = screen.getByRole('button', { name: 'Log In' });
    await user.click(submitButton);
    
    // Error should be announced to screen readers
    const errorMessage = await screen.findByRole('alert');
    expect(errorMessage).toHaveTextContent('Email is required');
    
    // Input should be marked as invalid
    const emailInput = screen.getByLabelText('Email');
    expect(emailInput).toHaveAttribute('aria-invalid', 'true');
  });

  test('labels are properly associated', () => {
    render(<LoginForm />);
    
    const emailInput = screen.getByLabelText('Email');
    expect(emailInput).toHaveAttribute('type', 'email');
    
    const passwordInput = screen.getByLabelText('Password');
    expect(passwordInput).toHaveAttribute('type', 'password');
  });
});
```

---

## Manual Testing Checklist

### Keyboard Navigation
- [ ] Can reach all interactive elements with Tab
- [ ] Can activate buttons with Enter/Space
- [ ] Can navigate dropdowns with Arrow keys
- [ ] Can close modals with Escape
- [ ] Focus order is logical
- [ ] No keyboard traps
- [ ] Focus indicators are visible (3:1 contrast)

### Screen Reader Testing
- [ ] All images have appropriate alt text
- [ ] Headings are in logical order
- [ ] Forms are properly labeled
- [ ] Error messages are announced
- [ ] Loading states are announced
- [ ] Dynamic content changes are announced
- [ ] Landmarks are properly used

### Visual Testing
- [ ] Text has 4.5:1 contrast (3:1 for large text)
- [ ] UI components have 3:1 contrast
- [ ] Color is not the only visual indicator
- [ ] Content reflows at 320px width
- [ ] Text can be resized to 200%
- [ ] No horizontal scrolling at 200% zoom

### Forms
- [ ] All inputs have visible labels
- [ ] Required fields are indicated
- [ ] Error messages are clear and helpful
- [ ] Errors are associated with fields (aria-describedby)
- [ ] Fields have autocomplete attributes
- [ ] Submit buttons are clearly labeled

### Interactive Elements
- [ ] Buttons have descriptive text
- [ ] Links are descriptive (not "click here")
- [ ] Disabled elements are clearly indicated
- [ ] Loading states are indicated
- [ ] Success/error messages are clear

---

## Color Contrast Tools

### WebAIM Contrast Checker
https://webaim.org/resources/contrastchecker/

### Coolors Contrast Checker
https://coolors.co/contrast-checker

### Chrome DevTools Contrast Checker
1. Inspect element
2. Check "Contrast ratio" in Styles panel
3. Adjust colors to pass AA/AAA

### VS Code Extensions
- Color Highlight
- ColorHelper

### Command Line Tool

```bash
npm install --save-dev color-contrast-checker
```

```js
const { contrast } = require('color-contrast-checker');

const textColor = '#767676';
const bgColor = '#ffffff';

console.log(contrast.ratio(textColor, bgColor)); // 4.58
console.log(contrast.isLevelAA(textColor, bgColor)); // true
console.log(contrast.isLevelAAA(textColor, bgColor)); // false
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Accessibility Tests

on: [push, pull_request]

jobs:
  a11y:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Build
        run: npm run build
        
      - name: Start server
        run: npm start &
        
      - name: Wait for server
        run: npx wait-on http://localhost:3000
        
      - name: Run pa11y
        run: npx pa11y-ci
        
      - name: Run Lighthouse CI
        run: npx lhci autorun
```

---

## Testing Checklist Summary

**Automated (catches ~30-40% of issues):**
- [ ] Run axe-core in development
- [ ] Run eslint-plugin-jsx-a11y
- [ ] Run jest-axe on components
- [ ] Run pa11y or Lighthouse CI
- [ ] Use browser extensions (WAVE, axe DevTools)

**Manual (catches remaining 60-70%):**
- [ ] Test keyboard navigation
- [ ] Test with screen reader
- [ ] Verify focus indicators
- [ ] Check color contrast
- [ ] Test at 200% zoom
- [ ] Test responsive reflow
- [ ] Review semantic HTML
- [ ] Test form validation

**Documentation:**
- [ ] Document known accessibility limitations
- [ ] Create accessibility statement
- [ ] Provide contact for accessibility issues
