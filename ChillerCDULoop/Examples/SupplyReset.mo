within ChillerCDULoop.Examples;
model SupplyReset
  "Variable-speed TCS pump and chilled-water setpoint reset from FWS pump speed"
  extends Modelica.Icons.Example;
  extends ChillerCDULoop.BaseClasses.PartialPlant;

  parameter Modelica.Units.SI.Temperature TChiSet_min=273.15 + 12
    "Lowest chiller leaving-water setpoint";
  parameter Modelica.Units.SI.TemperatureDifference dTChiSet_reset=12
    "Reset range above the lowest setpoint";
  parameter Real yFWS_target=0.85
    "FWS pump speed the reset loop aims for";

  Buildings.Controls.OBC.CDL.Reals.Sources.Constant dTTCSSet(k=dTTCS_nominal)
    "TCS temperature rise setpoint"
    annotation (Placement(transformation(extent={{20,-100},{40,-80}})));
  Buildings.Controls.OBC.CDL.Reals.Subtract dTTCS
    "Measured TCS temperature rise across cold plates"
    annotation (Placement(transformation(extent={{140,-100},{160,-80}})));
  Buildings.Controls.OBC.CDL.Reals.PID conTCS(
    controllerType=Buildings.Controls.OBC.CDL.Types.SimpleController.PI,
    k=1,
    Ti=120,
    r=dTTCS_nominal,
    yMax=1,
    yMin=0.3,
    reverseActing=false)
    "TCS pump speed holds the cold-plate temperature rise at setpoint"
    annotation (Placement(transformation(extent={{60,-100},{80,-80}})));

  Buildings.Controls.OBC.CDL.Reals.Sources.Constant yFWSSet(k=yFWS_target)
    "Target FWS pump speed for the reset loop"
    annotation (Placement(transformation(extent={{-160,20},{-140,40}})));
  Buildings.Controls.OBC.CDL.Reals.PID conRes(
    controllerType=Buildings.Controls.OBC.CDL.Types.SimpleController.PI,
    k=0.5,
    Ti=1800,
    yMax=1,
    yMin=0,
    reverseActing=true)
    "Raises the chiller setpoint while the FWS pump has spare capacity"
    annotation (Placement(transformation(extent={{-130,20},{-110,40}})));
  Buildings.Controls.OBC.CDL.Reals.MultiplyByParameter resGai(k=dTChiSet_reset)
    "Reset signal to setpoint offset"
    annotation (Placement(transformation(extent={{-100,20},{-90,30}})));
  Buildings.Controls.OBC.CDL.Reals.AddParameter TChiSet(p=TChiSet_min)
    "Chiller leaving-water setpoint"
    annotation (Placement(transformation(extent={{-86,20},{-76,30}})));

equation
  connect(senTTCSRet.T, dTTCS.u1);
  connect(senTTCSSup.T, dTTCS.u2);
  connect(dTTCSSet.y, conTCS.u_s);
  connect(dTTCS.y, conTCS.u_m);
  connect(conTCS.y, pumTCS.y);

  connect(yFWSSet.y, conRes.u_s);
  connect(conFWS.y, conRes.u_m);
  connect(conRes.y, resGai.u);
  connect(resGai.y, TChiSet.u);
  connect(TChiSet.y, chi.TSet);

annotation (
  experiment(StopTime=172800, Interval=60, Tolerance=1e-06),
  Documentation(info="<html>
<p>Same plant and same 30 &deg;C TCS supply setpoint as <code>Baseline</code>, with two changes:</p>
<ul>
<li>The TCS pump speed holds a 10 K temperature rise across the cold plates
(minimum speed 30%).</li>
<li>A slow PI loop raises the chiller leaving-water setpoint from 12 &deg;C up to
24 &deg;C while the FWS pump runs below 85% speed, and lowers it when the pump
needs more than that.</li>
</ul>
</html>"));
end SupplyReset;
