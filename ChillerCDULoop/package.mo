within ;
package ChillerCDULoop "Chiller, facility water loop, CDU and rack cold-plate loop for liquid-cooled data centers"
  extends Modelica.Icons.Package;

annotation (
  version="0.1.0",
  uses(Modelica(version="4.1.0"), Buildings(version="14.0.0")),
  Documentation(info="<html>
<p>System-level model of a liquid-cooled data-center pod. A water-cooled chiller
supplies the facility water system (FWS). A coolant distribution unit (CDU), modeled
as a counter-flow plate heat exchanger, transfers rack heat from the technology
cooling system (TCS) loop to the FWS loop. Cold plates are modeled as a prescribed
heat input proportional to IT load.</p>
<p>The examples compare two control sequences on chiller and pump energy at equal
TCS supply temperature.</p>
</html>"));
end ChillerCDULoop;
