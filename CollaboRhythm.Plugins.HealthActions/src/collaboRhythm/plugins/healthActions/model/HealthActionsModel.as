package collaboRhythm.plugins.healthActions.model
{
	import collaboRhythm.plugins.schedule.shared.model.IHealthActionModelDetailsProvider;
	import collaboRhythm.plugins.schedule.shared.model.MasterHealthActionInputControllerFactory;
	import collaboRhythm.plugins.schedule.shared.model.MasterHealthActionListViewAdapterFactory;
	import collaboRhythm.shared.model.Account;
	import collaboRhythm.shared.model.IApplicationNavigationProxy;
	import collaboRhythm.shared.model.ICollaborationLobbyNetConnectionServiceProxy;
	import collaboRhythm.shared.model.Record;
	import collaboRhythm.shared.model.healthRecord.DocumentCollectionBase;
	import collaboRhythm.shared.model.services.IComponentContainer;
	import collaboRhythm.shared.model.services.ICurrentDateSource;
	import collaboRhythm.shared.model.services.WorkstationKernel;

	import mx.binding.utils.BindingUtils;
	import mx.binding.utils.ChangeWatcher;
	import mx.collections.ArrayCollection;

	public class HealthActionsModel implements IHealthActionModelDetailsProvider
	{
		private var _record:Record;
		private var _accountId:String;
		private var _healthActionListViewAdapters:ArrayCollection;
		private var _healthActionInputControllerFactory:MasterHealthActionInputControllerFactory;
		private var _documentCollectionDependenciesArray:Array;
		private var _changeWatchers:Vector.<ChangeWatcher> = new Vector.<ChangeWatcher>();
		private var _componentContainer:IComponentContainer;
		private var _navigationProxy:IApplicationNavigationProxy;
		private var _collaborationLobbyNetConnectionServiceProxy:ICollaborationLobbyNetConnectionServiceProxy;
		private var _activeAccount:Account;
		private var _currentDateSource:ICurrentDateSource;

		public function HealthActionsModel(activeAccount:Account,
										   componentContainer:IComponentContainer,
										   record:Record, accountId:String,
										   navigationProxy:IApplicationNavigationProxy,
										   collaborationLobbyNetConnectionServiceProxy:ICollaborationLobbyNetConnectionServiceProxy)
		{
			_activeAccount = activeAccount;
			_componentContainer = componentContainer;
			_record = record;
			_accountId = accountId;
			_navigationProxy = navigationProxy;
			_collaborationLobbyNetConnectionServiceProxy = collaborationLobbyNetConnectionServiceProxy;
			_currentDateSource = WorkstationKernel.instance.resolve(ICurrentDateSource) as ICurrentDateSource;

			_documentCollectionDependenciesArray = [_record.medicationOrdersModel, _record.medicationScheduleItemsModel, _record.equipmentModel, _record.healthActionSchedulesModel, _record.adherenceItemsModel];

			for each (var documentCollection:DocumentCollectionBase in _documentCollectionDependenciesArray)
			{
				_changeWatchers.push(BindingUtils.bindSetter(init, documentCollection, "isStitched"));
			}
		}

		private function init(isStitched:Boolean):void
		{
			if (isStitched)
			{
				for each (var documentCollection:DocumentCollectionBase in _documentCollectionDependenciesArray)
				{
					if (!documentCollection.isStitched)
					{
						return;
					}
				}
			}
			else
			{
				return;
			}

			var healthActionListViewAdapterFactory:MasterHealthActionListViewAdapterFactory = new MasterHealthActionListViewAdapterFactory(_componentContainer);
			_healthActionListViewAdapters = healthActionListViewAdapterFactory.createUnscheduledHealthActionViewAdapters(this);
			_healthActionInputControllerFactory = new MasterHealthActionInputControllerFactory(_componentContainer);
		}

		public function get record():Record
		{
			return _record;
		}

		public function get accountId():String
		{
			return _accountId;
		}

		public function get healthActionListViewAdapters():ArrayCollection
		{
			return _healthActionListViewAdapters;
		}

		public function get healthActionInputControllerFactory():MasterHealthActionInputControllerFactory
		{
			return _healthActionInputControllerFactory;
		}

		public function get navigationProxy():IApplicationNavigationProxy
		{
			return _navigationProxy;
		}

		public function get collaborationLobbyNetConnectionServiceProxy():ICollaborationLobbyNetConnectionServiceProxy
		{
			return _collaborationLobbyNetConnectionServiceProxy;
		}

		public function get activeAccount():Account
		{
			return _activeAccount;
		}

		public function get componentContainer():IComponentContainer
		{
			return _componentContainer;
		}

		public function get currentDateSource():ICurrentDateSource
		{
			return _currentDateSource;
		}
	}
}
