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
11. [Target Size (WCAG 2.5.8)](#target-size-wcag-258--new-in-22)
12. [Focus Not Obscured (WCAG 2.4.11)](#focus-not-obscured-wcag-2411--new-in-22)
13. [Dragging Movements (WCAG 2.5.7)](#dragging-movements-wcag-257--new-in-22)
14. [Accessible Authentication (WCAG 3.3.8)](#accessible-authentication-wcag-338--new-in-22)
15. [Redundant Entry (WCAG 3.3.7)](#redundant-entry-wcag-337--new-in-22)
16. [Consistent Help (WCAG 3.2.6)](#consistent-help-wcag-326--new-in-22)

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

---

## Target Size (WCAG 2.5.8) — NEW in 2.2

### ❌ Target too small

```css
/* Bad - icon button only 16x16 */
.icon-btn {
  width: 16px;
  height: 16px;
  padding: 0;
}
```

```tsx
// Bad - React
<button
  onClick={handleClose}
  style={{ width: 16, height: 16, padding: 0 }}
>
  <CloseIcon />
</button>
```

### ✅ Target meets minimum 24×24 CSS pixels

```css
/* Good - meets minimum with padding */
.icon-btn {
  min-width: 44px;
  min-height: 44px;
  padding: 10px;
}

/* Also acceptable - exactly 24px with no adjacent targets overlapping */
.icon-btn {
  min-width: 24px;
  min-height: 24px;
  padding: 4px;
}
```

```tsx
// Good - React with proper sizing
<button
  onClick={handleClose}
  aria-label="Close dialog"
  style={{ minWidth: 44, minHeight: 44 }}
>
  <CloseIcon aria-hidden="true" />
</button>
```

### ❌ Standalone link styled too small

```html
<!-- Bad - standalone link too small to tap -->
<a href="/settings" style="font-size: 10px; padding: 2px;">Settings</a>
```

### ✅ Adequate sizing for standalone targets

```html
<!-- Good - adequate padding creates sufficient target area -->
<a href="/settings" style="padding: 8px; display: inline-block;">Settings</a>
```

---

## Focus Not Obscured (WCAG 2.4.11) — NEW in 2.2

### ❌ Focused element hidden behind sticky header

```css
/* Bad - sticky header obscures focused elements when scrolling */
.sticky-header {
  position: sticky;
  top: 0;
  z-index: 100;
  height: 60px;
}

/* No scroll-padding to account for sticky header */
html {
  scroll-behavior: smooth;
}
```

### ✅ Scroll padding accounts for sticky content

```css
/* Good - scroll-padding prevents focus from being hidden */
html {
  scroll-padding-top: 80px; /* sticky header height + buffer */
}

.sticky-header {
  position: sticky;
  top: 0;
  z-index: 100;
  height: 60px;
}
```

### ❌ Cookie banner obscures focused content

```html
<!-- Bad - fixed banner covers bottom of page, hiding focused elements -->
<div class="cookie-banner" style="position: fixed; bottom: 0; width: 100%; height: 80px; z-index: 999;">
  Accept cookies?
</div>
```

### ✅ Ensure focused elements remain visible

```html
<!-- Good - page has bottom padding to prevent banner overlap -->
<style>
  body { padding-bottom: 100px; } /* space for cookie banner */
  html { scroll-padding-bottom: 100px; }
</style>
<div class="cookie-banner" style="position: fixed; bottom: 0; width: 100%; z-index: 999;">
  Accept cookies?
  <button>Accept</button>
  <button>Decline</button>
</div>
```

```tsx
// Good - React: dismiss non-essential overlays on keyboard navigation
const CookieBanner = () => {
  const [visible, setVisible] = useState(true);

  if (!visible) return null;

  return (
    <div role="complementary" aria-label="Cookie consent"
      style={{ position: 'fixed', bottom: 0, width: '100%' }}>
      <p>We use cookies to improve your experience.</p>
      <button onClick={() => setVisible(false)}>Accept</button>
      <button onClick={() => setVisible(false)}>Decline</button>
    </div>
  );
};
```

---

## Dragging Movements (WCAG 2.5.7) — NEW in 2.2

### ❌ Drag-only reordering

```tsx
// Bad - no single-pointer alternative to drag
const SortableList = ({ items }: { items: Item[] }) => (
  <ul>
    {items.map(item => (
      <li
        key={item.id}
        draggable
        onDragStart={(e) => handleDragStart(e, item.id)}
        onDragOver={handleDragOver}
        onDrop={(e) => handleDrop(e, item.id)}
      >
        {item.name}
      </li>
    ))}
  </ul>
);
```

### ✅ Drag with move up/down buttons

```tsx
// Good - buttons as single-pointer alternative
const SortableList = ({ items }: { items: Item[] }) => (
  <ul>
    {items.map((item, index) => (
      <li
        key={item.id}
        draggable
        onDragStart={(e) => handleDragStart(e, item.id)}
        onDragOver={handleDragOver}
        onDrop={(e) => handleDrop(e, item.id)}
      >
        <span>{item.name}</span>
        <button
          aria-label={`Move ${item.name} up`}
          onClick={() => moveItem(index, index - 1)}
          disabled={index === 0}
        >
          ↑
        </button>
        <button
          aria-label={`Move ${item.name} down`}
          onClick={() => moveItem(index, index + 1)}
          disabled={index === items.length - 1}
        >
          ↓
        </button>
      </li>
    ))}
  </ul>
);
```

### ❌ Drag-only slider

```html
<!-- Bad - slider only works via drag -->
<div class="slider-track">
  <div class="slider-handle" onmousedown="startDrag(event)"></div>
</div>
```

### ✅ Slider with native input or click alternative

```html
<!-- Good - native range input handles all input modalities -->
<label for="volume">Volume:</label>
<input type="range" id="volume" min="0" max="100" value="50">
```

---

## Accessible Authentication (WCAG 3.3.8) — NEW in 2.2

### ❌ CAPTCHA requiring text transcription

```html
<!-- Bad - requires transcribing distorted text (cognitive function test) -->
<div class="captcha">
  <img src="/captcha-image" alt="Type the characters you see">
  <input type="text" name="captcha" placeholder="Enter CAPTCHA text">
</div>
```

### ✅ Authentication without cognitive tests

```html
<!-- Good - allows password managers via autocomplete -->
<form>
  <label for="email">Email:</label>
  <input type="email" id="email" autocomplete="username">

  <label for="password">Password:</label>
  <input type="password" id="password" autocomplete="current-password">
</form>

<!-- Good - WebAuthn / passkey (no cognitive test) -->
<button type="button" onclick="startWebAuthn()">Sign in with passkey</button>

<!-- Good - third-party auth -->
<button type="button" onclick="handleOAuth()">Sign in with Google</button>
```

### ❌ Password field with paste disabled

```html
<!-- Bad - prevents password managers from filling credentials -->
<input type="password" onpaste="return false;">
```

### ✅ Password manager friendly

```html
<!-- Good - paste allowed, autocomplete supports password managers -->
<label for="password">Password:</label>
<input type="password" id="password" autocomplete="current-password">
```

```tsx
// Good - React with verification code support
<label htmlFor="code">Verification code (sent to your email):</label>
<input
  type="text"
  id="code"
  autoComplete="one-time-code"
  inputMode="numeric"
/>
```

---

## Redundant Entry (WCAG 3.3.7) — NEW in 2.2

### ❌ Re-entering information across steps

```tsx
// Bad - user must re-type shipping address for billing
// Step 1 collected shipping address, Step 2 asks again from scratch
const BillingStep = () => (
  <form>
    <h2>Billing Address</h2>
    <input type="text" placeholder="Street address" />
    <input type="text" placeholder="City" />
    <input type="text" placeholder="State" />
    <input type="text" placeholder="ZIP code" />
  </form>
);
```

### ✅ Auto-populate or provide selection

```tsx
// Good - checkbox to reuse shipping address
const BillingStep = ({ shippingAddress }: { shippingAddress: Address }) => {
  const [useSameAddress, setUseSameAddress] = useState(false);
  const [billing, setBilling] = useState<Address>({});

  return (
    <form>
      <h2>Billing Address</h2>
      <label>
        <input
          type="checkbox"
          checked={useSameAddress}
          onChange={(e) => {
            setUseSameAddress(e.target.checked);
            if (e.target.checked) setBilling(shippingAddress);
          }}
        />
        Same as shipping address
      </label>
      {!useSameAddress && (
        <>
          <label htmlFor="billing-street">Street:</label>
          <input type="text" id="billing-street" value={billing.street || ''} onChange={handleChange} />
          {/* remaining fields */}
        </>
      )}
    </form>
  );
};
```

---

## Consistent Help (WCAG 3.2.6) — NEW in 2.2

### ❌ Help in different positions on different pages

```html
<!-- Page 1: help link in header -->
<header>
  <nav>
    <a href="/">Home</a>
    <a href="/help">Help</a>
    <a href="/about">About</a>
  </nav>
</header>

<!-- Page 2: help link moved to footer only -->
<footer>
  <a href="/help">Help</a>
</footer>
```

### ✅ Help in consistent relative order

```html
<!-- Good - help appears in same relative order on every page -->
<header>
  <nav>
    <a href="/">Home</a>
    <a href="/about">About</a>
    <a href="/help">Help</a>  <!-- Always last in nav -->
  </nav>
</header>
```

```tsx
// Good - React layout component ensures consistent help placement
const Layout = ({ children }: { children: React.ReactNode }) => (
  <>
    <header>
      <Nav />
      <a href="/help">Help</a>  {/* Always in header, after nav */}
    </header>
    <main>{children}</main>
    <footer>
      <a href="/help">Help</a>  {/* Always in footer, first link */}
      <a href="/contact">Contact Us</a>
    </footer>
  </>
);
```
