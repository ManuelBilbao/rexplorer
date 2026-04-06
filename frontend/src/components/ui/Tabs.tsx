import React, { createContext, useContext, useState } from "react";

interface TabsContextValue {
  activeIndex: number;
  setActiveIndex: (index: number) => void;
}

const TabsContext = createContext<TabsContextValue>({
  activeIndex: 0,
  setActiveIndex: () => {},
});

interface TabsProps {
  defaultIndex?: number;
  children: React.ReactNode;
}

export function Tabs({ defaultIndex = 0, children }: TabsProps) {
  const [activeIndex, setActiveIndex] = useState(defaultIndex);
  return (
    <TabsContext.Provider value={{ activeIndex, setActiveIndex }}>
      <div>{children}</div>
    </TabsContext.Provider>
  );
}

interface TabListProps {
  children: React.ReactNode;
}

export function TabList({ children }: TabListProps) {
  return (
    <div className="flex border-b border-rex-border">
      {React.Children.map(children, (child, index) => {
        if (React.isValidElement<TabInternalProps>(child)) {
          return React.cloneElement(child, { index });
        }
        return child;
      })}
    </div>
  );
}

interface TabInternalProps {
  index?: number;
}

interface TabProps {
  children: React.ReactNode;
  index?: number;
}

export function Tab({ children, index = 0 }: TabProps) {
  const { activeIndex, setActiveIndex } = useContext(TabsContext);
  const isActive = activeIndex === index;
  return (
    <button
      type="button"
      onClick={() => setActiveIndex(index)}
      className={`px-4 py-2 text-sm font-medium transition-colors focus:outline-none ${
        isActive
          ? "border-b-2 border-rex-primary text-rex-primary"
          : "text-rex-text-secondary hover:text-rex-text"
      }`}
    >
      {children}
    </button>
  );
}

interface TabPanelProps {
  index: number;
  children: React.ReactNode;
}

export function TabPanel({ index, children }: TabPanelProps) {
  const { activeIndex } = useContext(TabsContext);
  if (activeIndex !== index) return null;
  return <div className="py-4">{children}</div>;
}
