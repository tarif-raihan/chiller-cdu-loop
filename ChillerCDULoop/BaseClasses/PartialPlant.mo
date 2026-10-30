within ChillerCDULoop.BaseClasses;
partial model PartialPlant
  "Chiller, facility water loop, CDU and rack cold-plate loop without the TCS pump and chiller setpoint controls"

  package MediumW = Buildings.Media.Water "Water in all loops";

  parameter Modelica.Units.SI.HeatFlowRate QIT_nominal=200E3
    "Rack heat captured by cold plates at full IT load";
  parameter Modelica.Units.SI.TemperatureDifference dTTCS_nominal=10
    "TCS temperature rise across cold plates at design flow and load";
  parameter Modelica.Units.SI.TemperatureDifference dTFWS_nominal=8
    "FWS temperature rise across the CDU at design";
  parameter Modelica.Units.SI.MassFlowRate mTCS_flow_nominal=
    QIT_nominal/4184/dTTCS_nominal "TCS design mass flow rate";
  parameter Modelica.Units.SI.MassFlowRate mFWS_flow_nominal=
    QIT_nominal/4184/dTFWS_nominal "FWS design mass flow rate";
  parameter Modelica.Units.SI.Temperature TTCSSup_set=273.15 + 30
    "TCS supply temperature setpoint at the cold-plate inlet";
  parameter Modelica.Units.SI.Temperature TFWSSup_design=273.15 + 22
    "FWS supply temperature used to size the CDU";
  parameter Modelica.Units.SI.Temperature TConEnt=273.15 + 29.4
    "Condenser water entering temperature (fixed; no cooling tower model)";
  parameter Real etaCarnot=0.45
    "Chiller efficiency relative to the Carnot COP";

  Buildings.Fluid.Chillers.Carnot_TEva chi(
    redeclare package Medium1 = MediumW,
    redeclare package Medium2 = MediumW,
    QEva_flow_nominal=-1.2*QIT_nominal,
    dTEva_nominal=-dTFWS_nominal,
    dTCon_nominal=5.5,
    m2_flow_nominal=mFWS_flow_nominal,
    use_eta_Carnot_nominal=true,
    etaCarnot_nominal=etaCarnot,
    allowFlowReversal1=false,
    allowFlowReversal2=false,
    dp1_nominal=30000,
    dp2_nominal=30000) "Water-cooled chiller"
    annotation (Placement(transformation(extent={{-60,-10},{-40,10}})));

  Buildings.Fluid.Sources.MassFlowSource_T conSou(
    redeclare package Medium = MediumW,
    m_flow=chi.m1_flow_nominal,
    T=TConEnt,
    nPorts=1) "Condenser water supply"
    annotation (Placement(transformation(extent={{-100,0},{-80,20}})));
  Buildings.Fluid.Sources.Boundary_pT conSin(
    redeclare package Medium = MediumW, nPorts=1) "Condenser water return"
    annotation (Placement(transformation(extent={{-100,-30},{-80,-10}})));

  Buildings.Fluid.Movers.Preconfigured.SpeedControlled_y pumFWS(
    redeclare package Medium = MediumW,
    m_flow_nominal=mFWS_flow_nominal,
    dp_nominal=60000,
    allowFlowReversal=false) "Facility water pump"
    annotation (Placement(transformation(extent={{-10,-50},{-30,-30}})));
  Buildings.Fluid.Sources.Boundary_pT bouFWS(
    redeclare package Medium = MediumW, nPorts=1)
    "Pressure reference for the FWS loop"
    annotation (Placement(transformation(extent={{30,-70},{10,-50}})));
  Buildings.Fluid.Sensors.TemperatureTwoPort senTFWSSup(
    redeclare package Medium = MediumW,
    m_flow_nominal=mFWS_flow_nominal,
    allowFlowReversal=false) "FWS supply temperature"
    annotation (Placement(transformation(extent={{-20,30},{0,50}})));
  Buildings.Fluid.Sensors.TemperatureTwoPort senTFWSRet(
    redeclare package Medium = MediumW,
    m_flow_nominal=mFWS_flow_nominal,
    allowFlowReversal=false) "FWS return temperature"
    annotation (Placement(transformation(extent={{30,-50},{10,-30}})));

  Buildings.Fluid.HeatExchangers.PlateHeatExchangerEffectivenessNTU cdu(
    redeclare package Medium1 = MediumW,
    redeclare package Medium2 = MediumW,
    m1_flow_nominal=mTCS_flow_nominal,
    m2_flow_nominal=mFWS_flow_nominal,
    dp1_nominal=30000,
    dp2_nominal=30000,
    configuration=Buildings.Fluid.Types.HeatExchangerConfiguration.CounterFlow,
    use_Q_flow_nominal=true,
    Q_flow_nominal=QIT_nominal,
    T_a1_nominal=TTCSSup_set + dTTCS_nominal,
    T_a2_nominal=TFWSSup_design,
    allowFlowReversal1=false,
    allowFlowReversal2=false)
    "CDU heat exchanger; side 1 is TCS (hot), side 2 is FWS (cold)"
    annotation (Placement(transformation(extent={{40,-10},{60,10}})));

  Buildings.Fluid.Movers.Preconfigured.SpeedControlled_y pumTCS(
    redeclare package Medium = MediumW,
    m_flow_nominal=mTCS_flow_nominal,
    dp_nominal=80000,
    allowFlowReversal=false) "CDU secondary (TCS) pump"
    annotation (Placement(transformation(extent={{80,-50},{100,-30}})));
  Buildings.Fluid.Sources.Boundary_pT bouTCS(
    redeclare package Medium = MediumW, nPorts=1)
    "Pressure reference for the TCS loop (expansion tank)"
    annotation (Placement(transformation(extent={{50,-80},{70,-60}})));
  Buildings.Fluid.Sensors.TemperatureTwoPort senTTCSSup(
    redeclare package Medium = MediumW,
    m_flow_nominal=mTCS_flow_nominal,
    allowFlowReversal=false) "TCS supply temperature at cold-plate inlet"
    annotation (Placement(transformation(extent={{110,-50},{130,-30}})));
  Buildings.Fluid.HeatExchangers.HeaterCooler_u colPla(
    redeclare package Medium = MediumW,
    m_flow_nominal=mTCS_flow_nominal,
    dp_nominal=50000,
    Q_flow_nominal=QIT_nominal,
    allowFlowReversal=false) "Rack cold plates (heat input = IT load)"
    annotation (Placement(transformation(extent={{140,-10},{160,10}})));
  Buildings.Fluid.Sensors.TemperatureTwoPort senTTCSRet(
    redeclare package Medium = MediumW,
    m_flow_nominal=mTCS_flow_nominal,
    allowFlowReversal=false) "TCS return temperature at cold-plate outlet"
    annotation (Placement(transformation(extent={{130,30},{110,50}})));

  Modelica.Blocks.Sources.CombiTimeTable loa(
    table=[0, 0.5; 6, 0.5; 8, 0.9; 18, 0.9; 20, 0.6; 24, 0.5],
    timeScale=3600,
    smoothness=Modelica.Blocks.Types.Smoothness.LinearSegments,
    extrapolation=Modelica.Blocks.Types.Extrapolation.Periodic)
    "IT load fraction over a day"
    annotation (Placement(transformation(extent={{100,60},{120,80}})));

  Buildings.Controls.OBC.CDL.Reals.Sources.Constant TTCSSupSet(k=TTCSSup_set)
    "TCS supply temperature setpoint"
    annotation (Placement(transformation(extent={{-100,60},{-80,80}})));
  Buildings.Controls.OBC.CDL.Reals.PID conFWS(
    controllerType=Buildings.Controls.OBC.CDL.Types.SimpleController.PI,
    k=1,
    Ti=120,
    r=5,
    yMax=1,
    yMin=0.1,
    reverseActing=false)
    "FWS pump speed holds the TCS supply temperature at setpoint"
    annotation (Placement(transformation(extent={{-60,60},{-40,80}})));

  Modelica.Blocks.Continuous.Integrator EChi(k=1/3.6E6)
    "Chiller electric energy, kWh"
    annotation (Placement(transformation(extent={{-20,100},{0,120}})));
  Modelica.Blocks.Continuous.Integrator EPumFWS(k=1/3.6E6)
    "FWS pump electric energy, kWh"
    annotation (Placement(transformation(extent={{20,100},{40,120}})));
  Modelica.Blocks.Continuous.Integrator EPumTCS(k=1/3.6E6)
    "TCS pump electric energy, kWh"
    annotation (Placement(transformation(extent={{60,100},{80,120}})));
  Modelica.Blocks.Continuous.Integrator EIT(k=1/3.6E6)
    "IT heat delivered to cold plates, kWh"
    annotation (Placement(transformation(extent={{100,100},{120,120}})));
  Modelica.Blocks.Math.Gain QIT(k=QIT_nominal) "IT heat, W"
    annotation (Placement(transformation(extent={{140,60},{160,80}})));

equation
  // condenser side
  connect(conSou.ports[1], chi.port_a1);
  connect(chi.port_b1, conSin.ports[1]);

  // facility water loop: pump -> chiller evaporator -> CDU -> pump
  connect(pumFWS.port_b, chi.port_a2);
  connect(chi.port_b2, senTFWSSup.port_a);
  connect(senTFWSSup.port_b, cdu.port_a2);
  connect(cdu.port_b2, senTFWSRet.port_a);
  connect(senTFWSRet.port_b, pumFWS.port_a);
  connect(bouFWS.ports[1], pumFWS.port_a);

  // technology cooling loop: CDU -> pump -> cold plates -> CDU
  connect(cdu.port_b1, pumTCS.port_a);
  connect(pumTCS.port_b, senTTCSSup.port_a);
  connect(senTTCSSup.port_b, colPla.port_a);
  connect(colPla.port_b, senTTCSRet.port_a);
  connect(senTTCSRet.port_b, cdu.port_a1);
  connect(bouTCS.ports[1], pumTCS.port_a);

  // load and common control
  connect(loa.y[1], colPla.u);
  connect(TTCSSupSet.y, conFWS.u_s);
  connect(senTTCSSup.T, conFWS.u_m);
  connect(conFWS.y, pumFWS.y);

  // energy meters
  connect(chi.P, EChi.u);
  connect(pumFWS.P, EPumFWS.u);
  connect(pumTCS.P, EPumTCS.u);
  connect(loa.y[1], QIT.u);
  connect(QIT.y, EIT.u);

annotation (
  Diagram(coordinateSystem(extent={{-120,-100},{180,140}})),
  Documentation(info="<html>
<p>Shared plant for the examples. Subclasses add the TCS pump speed command
<code>pumTCS.y</code> and the chiller leaving-water setpoint <code>chi.TSet</code>.</p>
<h4>Main assumptions</h4>
<ul>
<li>All rack heat is captured by the liquid loop (no air-side heat).</li>
<li>The chiller is a Carnot-efficiency model with a constant fraction of the Carnot COP
and no part-load degradation. Condenser water enters at a fixed temperature.</li>
<li>The CDU is a counter-flow plate heat exchanger sized for 200 kW at a 40 &deg;C TCS
return and 22 &deg;C FWS supply. Effectiveness changes with flow (effectiveness-NTU).</li>
<li>Pipes, valves, bypasses and pump staging are not modeled.</li>
</ul>
</html>"));
end PartialPlant;
