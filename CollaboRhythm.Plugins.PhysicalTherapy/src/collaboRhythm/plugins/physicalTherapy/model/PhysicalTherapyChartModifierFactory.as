package collaboRhythm.plugins.physicalTherapy.model
{
	import collaboRhythm.shared.model.healthRecord.document.VitalSignsModel;
	import collaboRhythm.shared.ui.healthCharts.model.IChartModelDetails;
	import collaboRhythm.shared.ui.healthCharts.model.descriptors.IChartDescriptor;
	import collaboRhythm.shared.ui.healthCharts.model.descriptors.MeasurementChartDescriptor;
	import collaboRhythm.shared.ui.healthCharts.model.descriptors.MedicationChartDescriptor;
	import collaboRhythm.shared.ui.healthCharts.model.descriptors.VitalSignChartDescriptor;
	import collaboRhythm.shared.ui.healthCharts.model.modifiers.IChartModifier;
	import collaboRhythm.shared.ui.healthCharts.model.modifiers.IChartModifierFactory;

	public class PhysicalTherapyChartModifierFactory implements IChartModifierFactory
	{
		public function PhysicalTherapyChartModifierFactory()
		{
		}

		public function createChartModifier(chartDescriptor:IChartDescriptor, chartModelDetails:IChartModelDetails,
											currentChartModifier:IChartModifier):IChartModifier
		{
			if (isHealthActionPlanChartDescriptor(chartDescriptor))
				return new PhysicalTherapyChartModifier(chartDescriptor as MeasurementChartDescriptor, chartModelDetails, currentChartModifier);
			else
				return currentChartModifier;
		}

		public static function isHealthActionPlanChartDescriptor(chartDescriptor:IChartDescriptor):Boolean
		{
			return true;
			/*hartDescriptor is MedicationChartDescriptor &&
					(chartDescriptor as MedicationChartDescriptor).medicationCode ==
							PhysicalTherapyChartModifier.INSULIN_LEVEMIR_CODE;*/
		}
	}
}
