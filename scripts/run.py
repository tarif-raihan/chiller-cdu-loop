"""Simulate both control sequences, then write the summary table and figures.

Usage (from the repository root):
    python scripts/run.py                      # simulate + post-process
    python scripts/run.py --skip-sim           # post-process existing results
    python scripts/run.py --modelica-path "C:/libs/msl;C:/libs/buildings"
"""
import argparse
import csv
import subprocess
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
from omres import Result

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "results"
FIG = ROOT / "figures"
CASES = {"Baseline": "Baseline", "SupplyReset": "Supply reset"}
DAY = 86400.0


def simulate(omc, modelica_path):
    script = (ROOT / "scripts" / "simulate.mos").read_text()
    if modelica_path:
        script = f'setModelicaPath("{modelica_path}");\n' + script
    tmp = ROOT / "scripts" / "_run.mos"
    tmp.write_text(script)
    try:
        out = subprocess.run([omc, str(tmp)], cwd=ROOT, capture_output=True, text=True)
    finally:
        tmp.unlink(missing_ok=True)
    print(out.stdout[-2000:])
    if "The simulation finished successfully" not in out.stdout:
        sys.exit("Simulation failed; see the omc output above.")


def day2(r, name):
    return r.at(name, 2 * DAY) - r.at(name, DAY)


def summarize(results):
    rows = []
    for key, r in results.items():
        mask = r.time >= DAY
        e_chi, e_fws, e_tcs, e_it = (day2(r, n) for n in ("EChi.y", "EPumFWS.y", "EPumTCS.y", "EIT.y"))
        e_cool = e_chi + e_fws + e_tcs
        rows.append({
            "case": CASES[key],
            "IT heat [kWh]": e_it,
            "chiller [kWh]": e_chi,
            "FWS pump [kWh]": e_fws,
            "TCS pump [kWh]": e_tcs,
            "cooling total [kWh]": e_cool,
            "cooling/IT [-]": e_cool / e_it,
            "mean chiller COP [-]": -np.trapezoid(r("chi.QEva_flow")[mask], r.time[mask]) / 3.6e6 / e_chi,
            "max TCS supply [degC]": r("senTTCSSup.T")[mask].max() - 273.15,
            "max cold-plate outlet [degC]": r("senTTCSRet.T")[mask].max() - 273.15,
        })
    base = rows[0]["cooling total [kWh]"]
    for row in rows:
        row["change vs baseline [%]"] = 100 * (row["cooling total [kWh]"] - base) / base
    return rows


def write_table(rows):
    RES.mkdir(exist_ok=True)
    with open(RES / "summary.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=rows[0].keys())
        w.writeheader()
        w.writerows(rows)
    keys = list(rows[0].keys())
    lines = ["| " + " | ".join(keys) + " |", "|" + "---|" * len(keys)]
    for row in rows:
        cells = [row["case"]] + [f"{row[k]:.2f}" if "/" in k or "COP" in k else f"{row[k]:.1f}" for k in keys[1:]]
        lines.append("| " + " | ".join(cells) + " |")
    table = "\n".join(lines)
    (RES / "summary.md").write_text(table + "\n")
    print(table)


def plot(results):
    FIG.mkdir(exist_ok=True)
    styles = {"Baseline": dict(color="#1f3864"), "SupplyReset": dict(color="#00808a", ls="--")}
    hours = lambda r: (r.time - DAY) / 3600
    window = lambda r: r.time >= DAY

    fig, ax = plt.subplots(3, 1, figsize=(7, 7.5), sharex=True)
    for key, r in results.items():
        m, h = window(r), hours(r)
        ax[0].plot(h[m], r("chi.TSet")[m] - 273.15, label=CASES[key], **styles[key])
        ax[1].plot(h[m], r("senTTCSSup.T")[m] - 273.15, label=f"{CASES[key]}, supply", **styles[key])
        ax[1].plot(h[m], r("senTTCSRet.T")[m] - 273.15, label=f"{CASES[key]}, cold-plate outlet",
                   alpha=0.6, **styles[key])
        ax[2].plot(h[m], (r("chi.P")[m] + r("pumFWS.P")[m] + r("pumTCS.P")[m]) / 1e3,
                   label=CASES[key], **styles[key])
    ax[0].set_ylabel("Chiller setpoint [°C]")
    ax[1].set_ylabel("TCS temperature [°C]")
    ax[2].set_ylabel("Cooling power [kW]")
    ax[2].set_xlabel("Hour of day 2")
    ax[2].set_xlim(0, 24)
    for a in ax:
        a.grid(alpha=0.3)
        a.legend(fontsize=8, loc="best")
    fig.tight_layout()
    fig.savefig(FIG / "time_series.png", dpi=200)

    r = results["Baseline"]
    m = window(r)
    fig, ax = plt.subplots(figsize=(7, 2.5))
    ax.plot(hours(r)[m], r("colPla.Q_flow")[m] / 1e3, color="#444444")
    ax.set_ylabel("IT heat [kW]")
    ax.set_xlabel("Hour of day 2")
    ax.set_xlim(0, 24)
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(FIG / "it_load.png", dpi=200)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--omc", default="omc")
    p.add_argument("--modelica-path", default="")
    p.add_argument("--skip-sim", action="store_true")
    args = p.parse_args()
    if not args.skip_sim:
        simulate(args.omc, args.modelica_path)
    results = {k: Result(RES / f"ChillerCDULoop.Examples.{k}_res.mat") for k in CASES}
    write_table(summarize(results))
    plot(results)


if __name__ == "__main__":
    main()
