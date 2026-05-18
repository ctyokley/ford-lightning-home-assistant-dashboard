class LightningTempSliderCard extends HTMLElement {
  setConfig(config) {
    if (!config.entity) {
      throw new Error("Entity required");
    }
    this.config = {
      title: config.title || "Temperature",
      entity: config.entity,
      min: config.min ?? 60,
      max: config.max ?? 86,
      step: config.step ?? 1,
    };

    if (!this.shadowRoot) {
      this.attachShadow({ mode: "open" });
    }

    this._localValue = null;
    this._dragging = false;
  }

  set hass(hass) {
    this._hass = hass;
    this.render();
  }

  getCardSize() {
    return 2;
  }

  _label(v) {
    const n = Number(v);
    if (n <= 60) return "LO";
    if (n >= 86) return "HI";
    return `${n}°F`;
  }

  _percent(v) {
    const min = Number(this.config.min);
    const max = Number(this.config.max);
    return ((Number(v) - min) / (max - min)) * 100;
  }

  async _setValue(v) {
    await this._hass.callService("input_number", "set_value", {
      entity_id: this.config.entity,
      value: Number(v),
    });
  }

  render() {
    if (!this._hass || !this.config) return;

    const stateObj = this._hass.states[this.config.entity];

    if (!stateObj) {
      this.shadowRoot.innerHTML = `
        ${this._styles()}
        <ha-card>
          <div class="wrap missing">Entity not found: ${this.config.entity}</div>
        </ha-card>
      `;
      return;
    }

    const actual = Number(stateObj.state);
    const value = this._dragging && this._localValue !== null ? this._localValue : actual;
    const pct = this._percent(value);
    const label = this._label(value);

    this.shadowRoot.innerHTML = `
      ${this._styles()}
      <ha-card>
        <div class="wrap">
          <div class="header">
            <div class="title">${this.config.title}</div>
            <div class="current">${label}</div>
          </div>

          <div class="slider-block">
            <div class="bubble" style="left:${pct}%">${label}</div>
            <input
              id="slider"
              type="range"
              min="${this.config.min}"
              max="${this.config.max}"
              step="${this.config.step}"
              value="${value}"
            />
          </div>

          <div class="legend">
            <span class="lo">LO</span>
            <span>Cold</span>
            <span>Comfort</span>
            <span>Warm</span>
            <span class="hi">HI</span>
          </div>
        </div>
      </ha-card>
    `;

    const slider = this.shadowRoot.getElementById("slider");
    slider.addEventListener("input", (e) => {
      this._dragging = true;
      this._localValue = Number(e.target.value);
      const pct = this._percent(this._localValue);
      const label = this._label(this._localValue);
      const bubble = this.shadowRoot.querySelector(".bubble");
      const current = this.shadowRoot.querySelector(".current");
      bubble.style.left = `${pct}%`;
      bubble.textContent = label;
      current.textContent = label;
    });

    slider.addEventListener("change", async (e) => {
      const newValue = Number(e.target.value);
      try {
        await this._setValue(newValue);
      } finally {
        this._dragging = false;
        this._localValue = null;
      }
    });
  }

  _styles() {
    return `
      <style>
        ha-card {
          border-radius: 18px;
          overflow: hidden;
        }

        .wrap {
          padding: 16px 16px 14px 16px;
        }

        .missing {
          color: var(--error-color);
        }

        .header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 12px;
          margin-bottom: 16px;
        }

        .title {
          font-size: 16px;
          font-weight: 700;
          color: var(--primary-text-color);
        }

        .current {
          font-size: 22px;
          font-weight: 800;
          color: var(--primary-text-color);
        }

        .slider-block {
          position: relative;
          padding-top: 26px;
        }

        .bubble {
          position: absolute;
          top: 0;
          transform: translateX(-50%);
          background: var(--card-background-color);
          border: 1px solid var(--divider-color);
          box-shadow: var(--ha-card-box-shadow, 0 2px 6px rgba(0,0,0,0.25));
          border-radius: 999px;
          padding: 2px 8px;
          font-size: 12px;
          font-weight: 800;
          color: var(--primary-text-color);
          pointer-events: none;
          min-width: 44px;
          text-align: center;
        }

        input[type="range"] {
          width: 100%;
          appearance: none;
          -webkit-appearance: none;
          background: transparent;
          margin: 0;
          height: 34px;
          cursor: pointer;
        }

        input[type="range"]::-webkit-slider-runnable-track {
          height: 14px;
          border-radius: 999px;
          background: linear-gradient(
            90deg,
            #2563eb 0%,
            #3b82f6 18%,
            #93c5fd 35%,
            #facc15 55%,
            #fb923c 75%,
            #dc2626 100%
          );
        }

        input[type="range"]::-webkit-slider-thumb {
          -webkit-appearance: none;
          appearance: none;
          width: 28px;
          height: 28px;
          border-radius: 50%;
          background: #ffffff;
          border: 4px solid var(--primary-color);
          margin-top: -7px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.35);
        }

        input[type="range"]::-moz-range-track {
          height: 14px;
          border-radius: 999px;
          background: linear-gradient(
            90deg,
            #2563eb 0%,
            #3b82f6 18%,
            #93c5fd 35%,
            #facc15 55%,
            #fb923c 75%,
            #dc2626 100%
          );
        }

        input[type="range"]::-moz-range-thumb {
          width: 28px;
          height: 28px;
          border-radius: 50%;
          background: #ffffff;
          border: 4px solid var(--primary-color);
          box-shadow: 0 2px 8px rgba(0,0,0,0.35);
        }

        .legend {
          display: grid;
          grid-template-columns: repeat(5, 1fr);
          text-align: center;
          gap: 4px;
          margin-top: 8px;
          font-size: 12px;
          font-weight: 650;
          color: var(--secondary-text-color);
        }

        .legend .lo { color: #60a5fa; }
        .legend .hi { color: #f87171; }

        @media (max-width: 600px) {
          .wrap {
            padding: 14px 14px 12px 14px;
          }
          .current {
            font-size: 20px;
          }
          .legend {
            font-size: 11px;
          }
        }
      </style>
    `;
  }
}

if (!customElements.get("lightning-temp-slider-card")) {
  customElements.define("lightning-temp-slider-card", LightningTempSliderCard);
}

window.customCards = window.customCards || [];
if (!window.customCards.find((c) => c.type === "lightning-temp-slider-card")) {
  window.customCards.push({
    type: "lightning-temp-slider-card",
    name: "Lightning Temperature Slider Card",
    description: "Integrated FordPass-style temperature slider for remote climate",
  });
}
