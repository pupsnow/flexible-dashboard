package org.integratedsemantics.flexibledashboard.app
{
	import com.esria.samples.dashboard.events.LayoutChangeEvent;
	import com.esria.samples.dashboard.managers.PodLayoutManager;
	import com.esria.samples.dashboard.managers.StateManager;
	import com.esria.samples.dashboard.view.ChartContent;
	import com.esria.samples.dashboard.view.FormContent;
	import com.esria.samples.dashboard.view.ListContent;
	import com.esria.samples.dashboard.view.PieChartContent;
	import com.esria.samples.dashboard.view.Pod;
	import com.esria.samples.dashboard.view.PodContentBase;
	
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import flexlib.mdi.containers.MDICanvas;
	
	import mx.containers.ViewStack;
	import mx.controls.Alert;
	import mx.controls.TabBar;
	import mx.core.Application;
	import mx.events.IndexChangedEvent;
	import mx.events.ItemClickEvent;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	import org.integratedsemantics.flexibledashboard.birt.BirtReportViewerPod;
	import org.integratedsemantics.flexibledashboard.blazeds.BlazeDsPod;
	import org.integratedsemantics.flexibledashboard.calendar.CalendarPod;
	import org.integratedsemantics.flexibledashboard.flex.FlexAppPod;
	import org.integratedsemantics.flexibledashboard.html.IFramePod;
	import org.integratedsemantics.flexibledashboard.jasperreports.ReportPod;
	import org.integratedsemantics.flexibledashboard.olap.OlapGridPod;
	import org.integratedsemantics.flexibledashboard.pentaho.PentahoPod;


	public class FlexibleDashboardAppBase extends Application
	{
		public var modeViewStack:ViewStack;
		
		public var viewStack:ViewStack;
		public var tabBar:TabBar;
		
        // view modes
        public static const MAIN_VIEW_MODE_INDEX:int = 0;

		// Array of PodLayoutManagers
		protected var podLayoutManagers:Array = new Array();
		
		// Stores the xml data keyed off of a PodLayoutManager.
		protected var podDataDictionary:Dictionary = new Dictionary();
		
		// Stores PodLayoutManagers keyed off of a Pod.
		// Used for podLayoutManager calls after pods have been created for the first time.
		// Also, used for look-ups when saving pod content ViewStack changes.
		protected var podHash:Object = new Object();
		

		public function FlexibleDashboardAppBase()
		{
			super();
		}
					
        protected function onApplicationComplete(event:Event):void
        {
            modeViewStack.selectedIndex = MAIN_VIEW_MODE_INDEX; 
            onPortalCreationComplete();                              	
        }
					
		protected function onPortalCreationComplete():void
		{
			// Load pods.xml, which contains the pod layout.
			var httpService:HTTPService = new HTTPService();
			httpService.url = "data/flexibleDashboardPods.xml";
			httpService.resultFormat = "e4x";
			httpService.addEventListener(FaultEvent.FAULT, onFaultHttpService);
			httpService.addEventListener(ResultEvent.RESULT, onResultHttpService);
			httpService.send();
		}
		
		protected function onFaultHttpService(e:FaultEvent):void
		{
			Alert.show("Unable to load data/flexibleDashboardPods.xml.");
		}
		
		protected function onResultHttpService(e:ResultEvent):void
		{
			var viewXMLList:XMLList = e.result.view;
			var len:Number = viewXMLList.length();
			var containerWindowManagerHash:Object = new Object();
			for (var i:Number = 0; i < len; i++) // Loop through the view nodes.
			{
				// Create a canvas for each view node.
				//mdi var canvas:Canvas = new Canvas();
                var canvas:MDICanvas = new MDICanvas();				
				// PodLayoutManager handles resize and should prevent the need for
				// scroll bars so turn them off so they aren't visible during resizes.
				canvas.horizontalScrollPolicy = "off";
				canvas.verticalScrollPolicy = "off";
				canvas.label = viewXMLList[i].@label;
				canvas.percentWidth = 100;
				canvas.percentHeight = 100;								
				viewStack.addChild(canvas);
				// mdi
				canvas.windowManager.snapDistance = 16;
				canvas.windowManager.tilePadding = 10;
				
				// Create a manager for each view.
				var manager:PodLayoutManager = new PodLayoutManager();
				manager.container = canvas;
				manager.id = viewXMLList[i].@id;
				manager.addEventListener(LayoutChangeEvent.UPDATE, StateManager.setPodLayout);
				// Store the pod xml data. Used when view is first made visible.
				podDataDictionary[manager] = viewXMLList[i].pod;
				podLayoutManagers.push(manager);
			}
			
			var index:Number = StateManager.getViewIndex();
			// Make sure the index is not out of range.
			// This can happen if a tab view was saved but then tabs were subsequently removed from the XML.
			index = Math.min(tabBar.numChildren - 1, index);
			onItemClickTabBar(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, index));
			tabBar.selectedIndex = index;
		}
		
		protected function onItemClickTabBar(e:ItemClickEvent):void
		{
			var index:Number = e.index;
			StateManager.setViewIndex(index); // Save the view index.
			
			viewStack.selectedIndex = index;
			
			// If data exists then add the pods. After the pods have been added the data is cleared.
			var podLayoutManager:PodLayoutManager = podLayoutManagers[index];
			if (podDataDictionary[podLayoutManager] != null)
				addPods(podLayoutManagers[index]);
		}
		
		// Adds the pods to a view.
		protected function addPods(manager:PodLayoutManager):void
		{
			// Loop through the pod nodes for each view node.
			var podXMLList:XMLList = podDataDictionary[manager];
			var podLen:Number = podXMLList.length();
			var unsavedPodCount:Number = 0;
			for (var j:Number = 0; j < podLen; j++)
			{
				// Figure out which type of pod content to use.
				var podContent:PodContentBase = null;
				if (podXMLList[j].@type == "chart")
					podContent = new ChartContent();
				else if (podXMLList[j].@type == "form")
					podContent = new FormContent();
				else if (podXMLList[j].@type == "list")
					podContent = new ListContent();
				else if (podXMLList[j].@type == "pieChart")
					podContent = new PieChartContent();						
				else if (podXMLList[j].@type == "report")
				{
					podContent = new ReportPod();						
				}  											
				else if (podXMLList[j].@type == "pentaho")
				{
					podContent = new PentahoPod();						
				}  											
                else if (podXMLList[j].@type == "blazeds")
                {
                    podContent = new BlazeDsPod();                      
                }   
				else if (podXMLList[j].@type == "html")
				{
					podContent = new IFramePod();						
				}  											
                else if (podXMLList[j].@type == "flexApp")
                {
                    podContent = new FlexAppPod();                      
                }                                           
				else if (podXMLList[j].@type == "calendar")
				{
					podContent = new CalendarPod();						
				}  
                else if (podXMLList[j].@type == "olap-grid")
                {
                    podContent = new OlapGridPod();                     
                }  
                else if (podXMLList[j].@type == "birt-report")
                {
                    podContent = new BirtReportViewerPod();                     
                }  				
				
				if (podContent != null)
				{
					var viewId:String = manager.id;
					var podId:String = podXMLList[j].@id;
					
					// Get the saved value for the pod content viewStack.
					if (StateManager.getPodViewIndex(viewId, podId) != -1)
						podXMLList[j].@selectedViewIndex = StateManager.getPodViewIndex(viewId, podId);
					
					podContent.properties = podXMLList[j];
					var pod:Pod = new Pod();
					pod.id = podId;
					pod.title = podXMLList[j].@title;

					pod.addChild(podContent);
					
					var index:Number;
					
					if (StateManager.isPodMinimized(viewId, podId))
					{
						index = StateManager.getMinimizedPodIndex(viewId, podId);
						manager.addMinimizedItemAt(pod, index);
					}
					else
					{
						index = StateManager.getPodIndex(viewId, podId);
						
						// If the index hasn't been saved move the pod to the last position.
						if (index == -1)
						{
							index = podLen + unsavedPodCount;
							unsavedPodCount += 1;
						}
												
						manager.addItemAt(pod, index, StateManager.isPodMaximized(viewId, podId));						
					}
					
					pod.addEventListener(IndexChangedEvent.CHANGE, onChangePodView);
					
					podHash[pod] = manager;
				}
			}
			
			// Delete the saved data.
			delete podDataDictionary[manager];
			
            // Listen for the last pod to complete so the layout from the ContainerWindowManager is done correctly. 
            //mdi pod.addEventListener(FlexEvent.UPDATE_COMPLETE, onCreationCompletePod);   
            var argsArray:Array = new Array();
            argsArray.push(manager); 
            callLater(onCreationCompletePod, argsArray);
		}
		
		// Pod has been created so update the respective PodLayoutManager.
		// mdi protected function onCreationCompletePod(e:FlexEvent):void
        protected function onCreationCompletePod(manager:PodLayoutManager):void
		{
			//mdi e.currentTarget.removeEventListener(FlexEvent.UPDATE_COMPLETE, onCreationCompletePod);
			// mdi var manager:PodLayoutManager = PodLayoutManager(podHash[e.currentTarget]);
			manager.removeNullItems();
			//mdi manager.updateLayout(false);
			manager.tile();
		}
		
		// Saves the pod content ViewStack state.
		protected function onChangePodView(e:IndexChangedEvent):void
		{
			var pod:Pod = Pod(e.currentTarget);
			var viewId:String = PodLayoutManager(podHash[pod]).id;
			StateManager.setPodViewIndex(viewId, pod.id, e.newIndex);
		}
		
		// mdi
		protected function tile():void
		{
		    var index:int = viewStack.selectedIndex;
		    var mgr:PodLayoutManager = podLayoutManagers[index];
		    mgr.tile();  
		}
        
        // mdi
        protected function cascade():void
        {
            var index:int = viewStack.selectedIndex;
            var mgr:PodLayoutManager = podLayoutManagers[index];
            mgr.cascade();   
        }
				
	}
}