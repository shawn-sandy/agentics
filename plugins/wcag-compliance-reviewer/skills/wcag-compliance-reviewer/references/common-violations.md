# Common WCAG Violations and Fixes

This document provides common accessibility violations in HTML/CSS and React/TypeScript code with concrete fixes.

## Table of Contents

1. [Images and Alternative Text](#images-and-alternative-text)
2. [Forms and Labels](#forms-and-labels)
3. [Keyboard Accessibility](#keyboard-accessibility)
4. [Color and Contrast](#color-and-contrast)
5. [Semantic HTML](#semantic-html)
6. [Focus Management](#focus-management)
7. [ARIA Usage](#aria-usage)
8. [Interactive Elements](#interactive-elements)
9. [React/TypeScript Specific](#reacttypescript-specific)
10. [Dynamic Content](#dynamic-content)

---

## Images and Alternative Text

### ❌ Missing alt text

```html
<!-- Bad -->
<img src="logo.png">
<img src="profile.jpg">
```

```tsx
// Bad - React
<img src={logoUrl} />
```

### ✅ Proper alt text

```html
<!-- Good -->
<img src="logo.png" alt="Company Name Logo">
<img src="profile.jpg" alt="John Smith, CEO">
<img src="decorative-border.png" alt="" role="presentation">
```

```tsx
// Good - React
<img src={logoUrl} alt="Company Name Logo" />
<img src={decorativeImage} alt="" role="presentation" />
<img src={userAvatar} alt={`${user.name}'s profile picture`} />
```

### ❌ Redundant alt text

```html
<!-- Bad - "image of" is redundant -->
<img src="chart.png" alt="Image of sales chart">
```

### ✅ Concise, descriptive alt text

```html
<!-- Good -->
<img src="chart.png" alt="Sales chart showing 20% growth in Q4">
```

### ❌ Icon without text alternative

```tsx
// Bad
<button onClick={handleDelete}>
  <TrashIcon />
</button>
```

### ✅ Icon with aria-label or visible text

```tsx
// Good - aria-label
<button onClick={handleDelete} aria-label="Delete item">
  <TrashIcon aria-hidden="true" />
</button>

// Good - visible text
<button onClick={handleDelete}>
  <TrashIcon aria-hidden="true" />
  <span>Delete</span>
</button>

// Good - visually hidden text
<button onClick={handleDelete}>
  <TrashIcon aria-hidden="true" />
  <span className="sr-only">Delete item</span>
</button>
```

---

## Forms and Labels

### ❌ Input without label

```html
<!-- Bad -->
<input type="text" placeholder="Enter your name">
<input type="email">
```

```tsx
// Bad - React
<input type="email" placeholder="Email" />
```

### ✅ Input with proper label

```html
<!-- Good - explicit label -->
<label for="name">Name:</label>
<input type="text" id="name">

<!-- Good - implicit label -->
<label>
  Email:
  <input type="email">
</label>

<!-- Good - aria-label -->
<input type="search" aria-label="Search products">
```

```tsx
// Good - React
<label htmlFor="email">Email:</label>
<input type="email" id="email" />

// Good - aria-label
<input 
  type="search" 
  aria-label="Search products"
  placeholder="Search..."
/>
```

### ❌ Placeholder as label

```html
<!-- Bad - placeholder disappears on focus -->
<input type="email" placeholder="Email Address">
```

### ✅ Label + placeholder

```html
<!-- Good -->
<label for="email">Email Address</label>
<input type="email" id="email" placeholder="you@example.com">
```

### ❌ Missing autocomplete

```html
<!-- Bad - user data without autocomplete -->
<input type="email" id="email">
<input type="tel" id="phone">
```

### ✅ Proper autocomplete attributes

```html
<!-- Good -->
<input type="email" id="email" autocomplete="email">
<input type="tel" id="phone" autocomplete="tel">
<input type="text" id="fname" autocomplete="given-name">
<input type="text" id="lname" autocomplete="family-name">
<input type="text" id="street" autocomplete="street-address">
```

### ❌ Error without association

```html
<!-- Bad -->
<input type="email" id="email">
<div class="error">Invalid email format</div>
```

### ✅ Error with aria-describedby and aria-invalid

```html
<!-- Good -->
<label for="email">Email:</label>
<input 
  type="email" 
  id="email"
  aria-invalid="true"
  aria-describedby="email-error"
>
<div id="email-error" class="error">
  Invalid email format. Please enter a valid email address.
</div>
```

```tsx
// Good - React
const [email, setEmail] = useState('');
const [error, setError] = useState('');

<label htmlFor="email">Email:</label>
<input 
  type="email" 
  id="email"
  value={email}
  onChange={(e) => setEmail(e.target.value)}
  aria-invalid={!!error}
  aria-describedby={error ? "email-error" : undefined}
/>
{error && (
  <div id="email-error" className="error" role="alert">
    {error}
  </div>
)}
```

### ❌ Radio buttons without fieldset

```html
<!-- Bad -->
<label><input type="radio" name="plan" value="basic"> Basic</label>
<label><input type="radio" name="plan" value="pro"> Pro</label>
```

### ✅ Radio buttons with fieldset and legend

```html
<!-- Good -->
<fieldset>
  <legend>Choose your plan:</legend>
  <label><input type="radio" name="plan" value="basic"> Basic</label>
  <label><input type="radio" name="plan" value="pro"> Pro</label>
  <label><input type="radio" name="plan" value="enterprise"> Enterprise</label>
</fieldset>
```

---

## Keyboard Accessibility

### ❌ Click-only div button

```html
<!-- Bad - not keyboard accessible -->
<div class="button" onclick="handleClick()">Click me</div>
```

```tsx
// Bad - React
<div className="button" onClick={handleClick}>
  Click me
</div>
```

### ✅ Semantic button or keyboard-accessible div

```html
<!-- Good - use native button -->
<button type="button" onclick="handleClick()">Click me</button>

<!-- Acceptable if button not possible -->
<div 
  role="button" 
  tabindex="0"
  onclick="handleClick()"
  onkeydown="if(event.key === 'Enter' || event.key === ' ') handleClick()"
>
  Click me
</div>
```

```tsx
// Good - React
<button type="button" onClick={handleClick}>
  Click me
</button>

// Acceptable if button not possible
<div 
  role="button" 
  tabIndex={0}
  onClick={handleClick}
  onKeyDown={(e) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      handleClick();
    }
  }}
>
  Click me
</div>
```

### ❌ Keyboard trap in modal

```tsx
// Bad - focus can leave modal
const Modal = ({ children, onClose }) => (
  <div className="modal">
    <button onClick={onClose}>Close</button>
    {children}
  </div>
);
```

### ✅ Focus trapped in modal

```tsx
// Good - focus trapped, restored on close
import { useEffect, useRef } from 'react';

const Modal = ({ children, onClose }: { children: React.ReactNode, onClose: () => void }) => {
  const modalRef = useRef<HTMLDivElement>(null);
  const previousFocus = useRef<HTMLElement | null>(null);

  useEffect(() => {
    // Save current focus
    previousFocus.current = document.activeElement as HTMLElement;
    
    // Focus first focusable element in modal
    const focusableElements = modalRef.current?.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );
    if (focusableElements && focusableElements.length > 0) {
      (focusableElements[0] as HTMLElement).focus();
    }

    // Trap focus in modal
    const handleTab = (e: KeyboardEvent) => {
      if (e.key !== 'Tab' || !modalRef.current) return;

      const focusableElements = modalRef.current.querySelectorAll(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      );
      const firstElement = focusableElements[0] as HTMLElement;
      const lastElement = focusableElements[focusableElements.length - 1] as HTMLElement;

      if (e.shiftKey && document.activeElement === firstElement) {
        lastElement.focus();
        e.preventDefault();
      } else if (!e.shiftKey && document.activeElement === lastElement) {
        firstElement.focus();
        e.preventDefault();
      }
    };

    document.addEventListener('keydown', handleTab);

    return () => {
      document.removeEventListener('keydown', handleTab);
      // Restore focus on unmount
      previousFocus.current?.focus();
    };
  }, []);

  return (
    <div 
      ref={modalRef}
      role="dialog" 
      aria-modal="true"
      aria-labelledby="modal-title"
    >
      <h2 id="modal-title">Modal Title</h2>
      <button onClick={onClose}>Close</button>
      {children}
    </div>
  );
};
```

### ❌ Missing skip link

```html
<!-- Bad - no way to skip navigation -->
<nav>
  <!-- 20+ navigation links -->
</nav>
<main>
  <!-- Main content -->
</main>
```

### ✅ Skip to main content link

```html
<!-- Good -->
<a href="#main-content" class="skip-link">Skip to main content</a>
<nav>
  <!-- 20+ navigation links -->
</nav>
<main id="main-content">
  <!-- Main content -->
</main>

<style>
.skip-link {
  position: absolute;
  top: -40px;
  left: 0;
  background: #000;
  color: #fff;
  padding: 8px;
  z-index: 100;
}

.skip-link:focus {
  top: 0;
}
</style>
```

---

## Color and Contrast

### ❌ Insufficient color contrast

```css
/* Bad - contrast ratio 2.8:1 */
.text {
  color: #767676;
  background-color: #ffffff;
}

/* Bad - contrast ratio 2.5:1 */
.button {
  color: #ffffff;
  background-color: #4A90E2;
}
```

### ✅ Sufficient color contrast

```css
/* Good - contrast ratio 4.58:1 */
.text {
  color: #595959;
  background-color: #ffffff;
}

/* Good - contrast ratio 4.52:1 */
.button {
  color: #ffffff;
  background-color: #0066CC;
}
```

### ❌ Color-only indication

```tsx
// Bad - error indicated only by color
<input 
  type="email"
  style={{ borderColor: hasError ? 'red' : 'gray' }}
/>
```

### ✅ Multiple indicators

```tsx
// Good - error shown with color, icon, and text
<div>
  <input 
    type="email"
    aria-invalid={hasError}
    aria-describedby={hasError ? "email-error" : undefined}
    style={{ borderColor: hasError ? '#c00' : '#767676' }}
  />
  {hasError && (
    <div id="email-error" className="error">
      <ErrorIcon aria-hidden="true" />
      <span>Invalid email format</span>
    </div>
  )}
</div>
```

### ❌ Link distinguished only by color

```css
/* Bad */
a {
  color: blue;
  text-decoration: none;
}
```

### ✅ Link with additional visual indicator

```css
/* Good - underline */
a {
  color: blue;
  text-decoration: underline;
}

/* Good - icon or visual marker */
a {
  color: blue;
  text-decoration: none;
  border-bottom: 2px solid currentColor;
}
```

---

## Semantic HTML

### ❌ Divs for everything

```html
<!-- Bad -->
<div class="header">
  <div class="nav">...</div>
</div>
<div class="content">
  <div class="article">...</div>
</div>
<div class="footer">...</div>
```

### ✅ Semantic HTML5 elements

```html
<!-- Good -->
<header>
  <nav>...</nav>
</header>
<main>
  <article>...</article>
</main>
<footer>...</footer>
```

### ❌ Skipped heading levels

```html
<!-- Bad -->
<h1>Page Title</h1>
<h3>Section Title</h3> <!-- Skipped h2 -->
```

### ✅ Logical heading hierarchy

```html
<!-- Good -->
<h1>Page Title</h1>
<h2>Section Title</h2>
<h3>Subsection Title</h3>
```

### ❌ Non-semantic lists

```html
<!-- Bad -->
<div>
  <div>Item 1</div>
  <div>Item 2</div>
  <div>Item 3</div>
</div>
```

### ✅ Semantic lists

```html
<!-- Good -->
<ul>
  <li>Item 1</li>
  <li>Item 2</li>
  <li>Item 3</li>
</ul>
```

---

## Focus Management

### ❌ Invisible focus indicator

```css
/* Bad - removes focus indicator */
button:focus {
  outline: none;
}
```

### ✅ Visible focus indicator

```css
/* Good - custom focus indicator with sufficient contrast */
button:focus {
  outline: 2px solid #0066CC;
  outline-offset: 2px;
}

/* Good - using focus-visible for better UX */
button:focus-visible {
  outline: 2px solid #0066CC;
  outline-offset: 2px;
}

button:focus:not(:focus-visible) {
  outline: none;
}
```

### ❌ Elements incorrectly removed from tab order

```html
<!-- Bad -->
<button tabindex="-1">Important Action</button>
```

### ✅ Proper tab order management

```html
<!-- Good - button in natural tab order -->
<button>Important Action</button>

<!-- Acceptable - hiding decorative/redundant elements -->
<div class="icon-duplicate" tabindex="-1" aria-hidden="true">
  <svg>...</svg>
</div>
```

---

## ARIA Usage

### ❌ Redundant ARIA

```html
<!-- Bad - role redundant on native elements -->
<button role="button">Click me</button>
<nav role="navigation">...</nav>
```

### ✅ ARIA only when needed

```html
<!-- Good - no ARIA needed -->
<button>Click me</button>
<nav>...</nav>

<!-- Good - ARIA adds value -->
<div role="button" tabindex="0">Custom Button</div>
<nav aria-label="Primary navigation">...</nav>
```

### ❌ Missing ARIA labels on custom controls

```tsx
// Bad
<div onClick={handleToggle}>
  {isExpanded ? <ChevronUp /> : <ChevronDown />}
</div>
```

### ✅ Proper ARIA for custom controls

```tsx
// Good
<button
  onClick={handleToggle}
  aria-expanded={isExpanded}
  aria-label="Toggle details"
>
  {isExpanded ? <ChevronUp aria-hidden="true" /> : <ChevronDown aria-hidden="true" />}
</button>
```

### ❌ ARIA state not updated

```tsx
// Bad - aria-expanded never updates
<button aria-expanded="false" onClick={toggle}>
  Expand
</button>
```

### ✅ Dynamic ARIA state

```tsx
// Good
const [isExpanded, setIsExpanded] = useState(false);

<button 
  aria-expanded={isExpanded} 
  onClick={() => setIsExpanded(!isExpanded)}
>
  {isExpanded ? 'Collapse' : 'Expand'}
</button>
```

---

## Interactive Elements

### ❌ Accordion without proper ARIA

```tsx
// Bad
const Accordion = () => {
  const [open, setOpen] = useState(false);
  
  return (
    <div>
      <div onClick={() => setOpen(!open)}>
        Section Title
      </div>
      {open && <div>Content</div>}
    </div>
  );
};
```

### ✅ Accessible accordion

```tsx
// Good
const Accordion = () => {
  const [open, setOpen] = useState(false);
  const contentId = useId();
  const buttonId = useId();
  
  return (
    <div>
      <h3>
        <button 
          id={buttonId}
          aria-expanded={open}
          aria-controls={contentId}
          onClick={() => setOpen(!open)}
        >
          Section Title
        </button>
      </h3>
      <div 
        id={contentId}
        role="region"
        aria-labelledby={buttonId}
        hidden={!open}
      >
        Content
      </div>
    </div>
  );
};
```

### ❌ Tabs without keyboard navigation

```tsx
// Bad
const Tabs = ({ tabs }: { tabs: Array<{label: string, content: string}> }) => {
  const [active, setActive] = useState(0);
  
  return (
    <div>
      <div>
        {tabs.map((tab, i) => (
          <div key={i} onClick={() => setActive(i)}>
            {tab.label}
          </div>
        ))}
      </div>
      <div>{tabs[active].content}</div>
    </div>
  );
};
```

### ✅ Accessible tabs with keyboard navigation

```tsx
// Good
const Tabs = ({ tabs }: { tabs: Array<{label: string, content: string}> }) => {
  const [activeTab, setActiveTab] = useState(0);
  
  const handleKeyDown = (e: React.KeyboardEvent, index: number) => {
    if (e.key === 'ArrowRight') {
      setActiveTab((index + 1) % tabs.length);
    } else if (e.key === 'ArrowLeft') {
      setActiveTab((index - 1 + tabs.length) % tabs.length);
    } else if (e.key === 'Home') {
      setActiveTab(0);
    } else if (e.key === 'End') {
      setActiveTab(tabs.length - 1);
    }
  };
  
  return (
    <div>
      <div role="tablist" aria-label="Content tabs">
        {tabs.map((tab, i) => (
          <button
            key={i}
            role="tab"
            aria-selected={activeTab === i}
            aria-controls={`panel-${i}`}
            id={`tab-${i}`}
            tabIndex={activeTab === i ? 0 : -1}
            onClick={() => setActiveTab(i)}
            onKeyDown={(e) => handleKeyDown(e, i)}
          >
            {tab.label}
          </button>
        ))}
      </div>
      {tabs.map((tab, i) => (
        <div
          key={i}
          role="tabpanel"
          id={`panel-${i}`}
          aria-labelledby={`tab-${i}`}
          hidden={activeTab !== i}
          tabIndex={0}
        >
          {tab.content}
        </div>
      ))}
    </div>
  );
};
```

---

## React/TypeScript Specific

### ❌ Fragment without key in lists

```tsx
// Bad - can cause focus issues
{items.map(item => (
  <>
    <div>{item.title}</div>
    <div>{item.description}</div>
  </>
))}
```

### ✅ Fragment with key or single wrapper

```tsx
// Good - fragment with key
{items.map(item => (
  <Fragment key={item.id}>
    <div>{item.title}</div>
    <div>{item.description}</div>
  </Fragment>
))}

// Good - single wrapper
{items.map(item => (
  <div key={item.id}>
    <div>{item.title}</div>
    <div>{item.description}</div>
  </div>
))}
```

### ❌ Ref not forwarded to DOM element

```tsx
// Bad - ref doesn't reach actual element
const CustomButton = ({ children, ...props }) => (
  <div className="button-wrapper">
    <button {...props}>{children}</button>
  </div>
);
```

### ✅ Ref forwarded properly

```tsx
// Good
const CustomButton = forwardRef<HTMLButtonElement, React.ButtonHTMLAttributes<HTMLButtonElement>>(
  ({ children, ...props }, ref) => (
    <div className="button-wrapper">
      <button ref={ref} {...props}>{children}</button>
    </div>
  )
);
CustomButton.displayName = 'CustomButton';
```

### ❌ Missing TypeScript types for accessibility props

```tsx
// Bad - no type safety for a11y props
interface ButtonProps {
  onClick: () => void;
  children: React.ReactNode;
}
```

### ✅ Proper TypeScript types

```tsx
// Good
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  children: React.ReactNode;
}

// Good - explicit a11y props
interface ToggleButtonProps {
  'aria-expanded': boolean;
  'aria-controls': string;
  onClick: () => void;
  children: React.ReactNode;
}
```

---

## Dynamic Content

### ❌ Status updates without announcement

```tsx
// Bad - screen reader users don't know about status change
const SaveStatus = () => {
  const [status, setStatus] = useState('idle');
  
  return <div>{status === 'saved' && 'Changes saved!'}</div>;
};
```

### ✅ Status announced with ARIA live region

```tsx
// Good
const SaveStatus = () => {
  const [status, setStatus] = useState('idle');
  
  return (
    <div role="status" aria-live="polite">
      {status === 'saved' && 'Changes saved successfully!'}
      {status === 'error' && 'Error saving changes'}
    </div>
  );
};
```

### ❌ Loading state without indication

```tsx
// Bad
const DataDisplay = () => {
  const { data, isLoading } = useQuery();
  
  return isLoading ? null : <div>{data}</div>;
};
```

### ✅ Loading state announced

```tsx
// Good
const DataDisplay = () => {
  const { data, isLoading } = useQuery();
  
  if (isLoading) {
    return (
      <div role="status" aria-live="polite">
        Loading data...
      </div>
    );
  }
  
  return <div>{data}</div>;
};
```

### ❌ Alert without proper role

```tsx
// Bad
const Alert = ({ message }: { message: string }) => (
  <div className="alert">{message}</div>
);
```

### ✅ Alert with role and aria-live

```tsx
// Good
const Alert = ({ message, type = 'info' }: { message: string, type?: 'info' | 'error' | 'success' }) => (
  <div 
    role="alert" 
    aria-live="assertive"
    className={`alert alert-${type}`}
  >
    {message}
  </div>
);
```

---

## CSS-only Toggle/Hide Patterns

### ❌ Content hidden with CSS but still in tab order

```html
<!-- Bad -->
<div class="hidden-content">
  <button>I'm still focusable!</button>
</div>

<style>
.hidden-content {
  display: none; /* This hides visually but button is still in tab order in some cases */
}
</style>
```

### ✅ Content properly hidden

```html
<!-- Good - use hidden attribute -->
<div hidden>
  <button>Not focusable</button>
</div>

<!-- Good - inert attribute (modern browsers) -->
<div inert>
  <button>Not interactive</button>
</div>
```

```tsx
// Good - React conditional rendering
{isVisible && (
  <div>
    <button>Only rendered when visible</button>
  </div>
)}
```

---

## Screen Reader-Only Text

### Helper class for visually hidden but screen-reader accessible content:

```css
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}
```

Usage:

```html
<button>
  <TrashIcon aria-hidden="true" />
  <span class="sr-only">Delete item</span>
</button>
```

```tsx
// React
<button>
  <TrashIcon aria-hidden="true" />
  <span className="sr-only">Delete item</span>
</button>
```
