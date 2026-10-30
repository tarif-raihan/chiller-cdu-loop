within ChillerCDULoop.Examples;
model Baseline
  "Fixed 12 degC chilled-water setpoint and constant-speed TCS pump"
  extends Modelica.Icons.Example;
  extends ChillerCDULoop.BaseClasses.PartialPlant;

  Buildings.Controls.OBC.CDL.Reals.Sources.Constant TChiSet(k=273.15 + 12)
    "Chiller leaving-water setpoint"
    annotation (Placement(transformation(extent={{-100,20},{-80,40}})));
  Buildings.Controls.OBC.CDL.Reals.Sources.Constant yTCS(k=1)
    "TCS pump at full speed"
    annotation (Placement(transformation(extent={{60,-100},{80,-80}})));

equation
  connect(TChiSet.y, chi.TSet);
  connect(yTCS.y, pumTCS.y);

annotation (
  experiment(StopTime=172800, Interval=60, Tolerance=1e-06),
  Documentation(info="<html>
<p>Reference sequence. The chiller holds 12 &deg;C leaving water at all loads.
The TCS pump runs at design speed, so the TCS temperature rise falls at part load.
The FWS pump speed holds the TCS supply temperature at 30 &deg;C.</p>
</html>"));
end Baseline;
