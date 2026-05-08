import { render, screen, fireEvent } from "@testing-library/react";
import { Tabs } from "./Tabs";

const basicTabs = [
  { id: "t1", label: "Tab One", content: <p>Panel One</p> },
  { id: "t2", label: "Tab Two", content: <p>Panel Two</p> },
  { id: "t3", label: "Tab Three", content: <p>Panel Three</p> },
];

const withDisabledTab = [
  { id: "t1", label: "Tab One", content: <p>Panel One</p> },
  { id: "t2", label: "Tab Two", content: <p>Panel Two</p>, disabled: true },
  { id: "t3", label: "Tab Three", content: <p>Panel Three</p> },
];

describe("Tabs — criterion 1: structure", () => {
  it("renders one tablist, N tabs, and N tabpanels", () => {
    render(<Tabs tabs={basicTabs} defaultTab="t1" />);
    expect(screen.getByRole("tablist")).toBeInTheDocument();
    expect(screen.getAllByRole("tab")).toHaveLength(3);
    expect(screen.getAllByRole("tabpanel")).toHaveLength(3);
  });
});

describe("Tabs — criterion 2: initial selection and visibility", () => {
  it("exactly one tab has aria-selected=true", () => {
    render(<Tabs tabs={basicTabs} defaultTab="t1" />);
    const selected = screen.getAllByRole("tab").filter(
      (t) => t.getAttribute("aria-selected") === "true"
    );
    expect(selected).toHaveLength(1);
  });

  it("selected tab's panel is visible; others have hidden attribute", () => {
    render(<Tabs tabs={basicTabs} defaultTab="t1" />);
    const panels = screen.getAllByRole("tabpanel", { hidden: true });
    const visible = panels.filter((p) => !p.hasAttribute("hidden"));
    const hidden = panels.filter((p) => p.hasAttribute("hidden"));
    expect(visible).toHaveLength(1);
    expect(hidden).toHaveLength(2);
  });
});

describe("Tabs — criterion 3: click to select", () => {
  it("clicking a tab makes it selected and shows its panel", () => {
    render(<Tabs tabs={basicTabs} defaultTab="t1" />);
    const tabs = screen.getAllByRole("tab");
    fireEvent.click(tabs[1]);
    expect(tabs[1]).toHaveAttribute("aria-selected", "true");
    expect(tabs[0]).toHaveAttribute("aria-selected", "false");
    const panels = screen.getAllByRole("tabpanel", { hidden: true });
    expect(panels[1]).not.toHaveAttribute("hidden");
    expect(panels[0]).toHaveAttribute("hidden");
  });
});

describe("Tabs — criterion 4: ArrowRight / ArrowLeft navigation", () => {
  it("ArrowRight moves selection to the next tab", () => {
    render(<Tabs tabs={basicTabs} defaultTab="t1" />);
    const tabs = screen.getAllByRole("tab");
    tabs[0].focus();
    fireEvent.keyDown(tabs[0], { key: "ArrowRight" });
    expect(tabs[1]).toHaveAttribute("aria-selected", "true");
  });

  it("ArrowLeft moves selection to the previous tab", () => {
    render(<Tabs tabs={basicTabs} defaultTab="t2" />);
    const tabs = screen.getAllByRole("tab");
    tabs[1].focus();
    fireEvent.keyDown(tabs[1], { key: "ArrowLeft" });
    expect(tabs[0]).toHaveAttribute("aria-selected", "true");
  });

  it("ArrowRight wraps from last tab to first", () => {
    render(<Tabs tabs={basicTabs} defaultTab="t3" />);
    const tabs = screen.getAllByRole("tab");
    tabs[2].focus();
    fireEvent.keyDown(tabs[2], { key: "ArrowRight" });
    expect(tabs[0]).toHaveAttribute("aria-selected", "true");
  });

  it("ArrowLeft wraps from first tab to last", () => {
    render(<Tabs tabs={basicTabs} defaultTab="t1" />);
    const tabs = screen.getAllByRole("tab");
    tabs[0].focus();
    fireEvent.keyDown(tabs[0], { key: "ArrowLeft" });
    expect(tabs[2]).toHaveAttribute("aria-selected", "true");
  });
});

describe("Tabs — criterion 5: Home / End navigation", () => {
  it("Home jumps to the first tab", () => {
    render(<Tabs tabs={basicTabs} defaultTab="t3" />);
    const tabs = screen.getAllByRole("tab");
    tabs[2].focus();
    fireEvent.keyDown(tabs[2], { key: "Home" });
    expect(tabs[0]).toHaveAttribute("aria-selected", "true");
  });

  it("End jumps to the last tab", () => {
    render(<Tabs tabs={basicTabs} defaultTab="t1" />);
    const tabs = screen.getAllByRole("tab");
    tabs[0].focus();
    fireEvent.keyDown(tabs[0], { key: "End" });
    expect(tabs[2]).toHaveAttribute("aria-selected", "true");
  });
});

describe("Tabs — criterion 6: aria-controls and aria-labelledby", () => {
  it("each tab's aria-controls points to its panel's id", () => {
    render(<Tabs tabs={basicTabs} defaultTab="t1" />);
    const tabs = screen.getAllByRole("tab");
    const panels = screen.getAllByRole("tabpanel", { hidden: true });
    tabs.forEach((tab, i) => {
      const panelId = tab.getAttribute("aria-controls");
      expect(panelId).toBeTruthy();
      expect(panels[i].getAttribute("id")).toBe(panelId);
    });
  });

  it("each panel's aria-labelledby points to its tab's id", () => {
    render(<Tabs tabs={basicTabs} defaultTab="t1" />);
    const tabs = screen.getAllByRole("tab");
    const panels = screen.getAllByRole("tabpanel", { hidden: true });
    panels.forEach((panel, i) => {
      const tabId = panel.getAttribute("aria-labelledby");
      expect(tabId).toBeTruthy();
      expect(tabs[i].getAttribute("id")).toBe(tabId);
    });
  });
});

describe("Tabs — criterion 7: disabled tabs", () => {
  it("disabled tab has aria-disabled=true", () => {
    render(<Tabs tabs={withDisabledTab} defaultTab="t1" />);
    const tabs = screen.getAllByRole("tab");
    expect(tabs[1]).toHaveAttribute("aria-disabled", "true");
  });

  it("clicking a disabled tab does not change selection", () => {
    render(<Tabs tabs={withDisabledTab} defaultTab="t1" />);
    const tabs = screen.getAllByRole("tab");
    fireEvent.click(tabs[1]);
    expect(tabs[0]).toHaveAttribute("aria-selected", "true");
    expect(tabs[1]).toHaveAttribute("aria-selected", "false");
  });

  it("ArrowRight skips disabled tabs", () => {
    render(<Tabs tabs={withDisabledTab} defaultTab="t1" />);
    const tabs = screen.getAllByRole("tab");
    tabs[0].focus();
    fireEvent.keyDown(tabs[0], { key: "ArrowRight" });
    expect(tabs[2]).toHaveAttribute("aria-selected", "true");
  });
});

describe("Tabs — criterion 8: roving tabindex", () => {
  it("selected tab has tabindex=0; others have tabindex=-1", () => {
    render(<Tabs tabs={basicTabs} defaultTab="t1" />);
    const tabs = screen.getAllByRole("tab");
    expect(tabs[0]).toHaveAttribute("tabindex", "0");
    expect(tabs[1]).toHaveAttribute("tabindex", "-1");
    expect(tabs[2]).toHaveAttribute("tabindex", "-1");
  });

  it("tabindex updates when selection changes", () => {
    render(<Tabs tabs={basicTabs} defaultTab="t1" />);
    const tabs = screen.getAllByRole("tab");
    fireEvent.click(tabs[1]);
    expect(tabs[1]).toHaveAttribute("tabindex", "0");
    expect(tabs[0]).toHaveAttribute("tabindex", "-1");
  });
});

describe("Tabs — criterion 9: tabpanel focusability", () => {
  it("every tabpanel has tabindex=0", () => {
    render(<Tabs tabs={basicTabs} defaultTab="t1" />);
    const panels = screen.getAllByRole("tabpanel", { hidden: true });
    panels.forEach((panel) => {
      expect(panel).toHaveAttribute("tabindex", "0");
    });
  });
});
