import { useState, KeyboardEvent } from "react";

export interface TabItem {
  id: string;
  label: string;
  content: React.ReactNode;
  disabled?: boolean;
}

interface TabsProps {
  tabs: TabItem[];
  defaultTab: string;
}

export function Tabs({ tabs, defaultTab }: TabsProps) {
  const [selected, setSelected] = useState(defaultTab);

  function selectTab(id: string) {
    const tab = tabs.find((t) => t.id === id);
    if (!tab || tab.disabled) return;
    setSelected(id);
  }

  function handleKeyDown(e: KeyboardEvent<HTMLButtonElement>, id: string) {
    const enabledIdList = tabs.filter((t) => !t.disabled).map((t) => t.id);
    const idx = enabledIdList.indexOf(id);

    if (e.key === "ArrowRight") {
      const next = enabledIdList[(idx + 1) % enabledIdList.length];
      setSelected(next);
    } else if (e.key === "ArrowLeft") {
      const prev =
        enabledIdList[(idx - 1 + enabledIdList.length) % enabledIdList.length];
      setSelected(prev);
    } else if (e.key === "Home") {
      setSelected(enabledIdList[0]);
    } else if (e.key === "End") {
      setSelected(enabledIdList[enabledIdList.length - 1]);
    }
  }

  return (
    <div>
      <div role="tablist">
        {tabs.map((tab) => {
          const isSelected = tab.id === selected;
          return (
            <button
              key={tab.id}
              id={tab.id}
              role="tab"
              aria-selected={isSelected ? "true" : "false"}
              aria-controls={`panel-${tab.id}`}
              aria-disabled={tab.disabled ? "true" : undefined}
              tabIndex={isSelected ? 0 : -1}
              onClick={() => selectTab(tab.id)}
              onKeyDown={(e) => !tab.disabled && handleKeyDown(e, tab.id)}
            >
              {tab.label}
            </button>
          );
        })}
      </div>
      {tabs.map((tab) => (
        <div
          key={tab.id}
          id={`panel-${tab.id}`}
          role="tabpanel"
          aria-labelledby={tab.id}
          tabIndex={0}
          hidden={tab.id !== selected}
        >
          {tab.content}
        </div>
      ))}
    </div>
  );
}
