import { useEffect, useState } from "react";
import ArchitectureTour from "./components/ArchitectureTour";
import SQLPlayground from "./pages/SQLPlayground";
import { getHealth } from "./api";

export default function App() {
  const [tourStep, setTourStep] = useState(0);
  const [showTour, setShowTour] = useState(false);
  const [health, setHealth] = useState<string>("checking...");

  useEffect(() => {
    const seen = localStorage.getItem("tinystack_tour_done");
    if (!seen) setShowTour(true);
    getHealth()
      .then((h) => setHealth(h.status))
      .catch(() => setHealth("offline"));
  }, []);

  const closeTour = () => {
    localStorage.setItem("tinystack_tour_done", "1");
    setShowTour(false);
  };

  return (
    <>
      <header className="app-header">
        <h1>
          TinyStack
          <span className="badge">SQL + AI Playground</span>
        </h1>
        <span style={{ fontSize: 13, color: "#94a3b8" }}>API: {health}</span>
      </header>
      <SQLPlayground />
      {showTour && (
        <ArchitectureTour
          step={tourStep}
          onNext={() => setTourStep((s) => s + 1)}
          onClose={closeTour}
        />
      )}
    </>
  );
}
