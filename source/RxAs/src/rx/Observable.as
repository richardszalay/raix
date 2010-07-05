package rx
{
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.errors.IllegalOperationError;
	import flash.events.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.Dictionary;
	
	import mx.collections.ICollectionView;
	import mx.collections.IViewCursor;
	import mx.rpc.AsyncToken;
	
	import rx.flex.*;
	import rx.impl.*;
	import rx.scheduling.*;
	import rx.util.ErrorUtil;

	public class Observable
	{
		private static var _unhandledErrorsSubject : Subject = new Subject(Error);
		
		public function Observable()
		{
			throw new IllegalOperationError("This class is static and cannot be instantiated. Create an IObservable by using one of Observable's static methods");
		}
		
		public static function amb(sources : Array/*.<IObservable>*/) : IObservable
		{
			sources = sources.slice();
			
			return new ClosureObservable(int, function(observer : IObserver) : ICancelable
			{
				var subscription : CompositeCancelable = new CompositeCancelable([])
			
				for each(var source : IObservable in sources)
				{
					(function(obs:IObservable):void
					{
						var futureSubscription : FutureCancelable = new FutureCancelable();
						subscription.add(futureSubscription);
					
						futureSubscription.innerSubscription = obs.subscribe(
							function(pl:Object) : void
							{
								var newSubscriptions : CompositeCancelable = 
									new CompositeCancelable(subscription.subscriptions);
									
								newSubscriptions.remove(futureSubscription);
								newSubscriptions.cancel();
								
								observer.onNext(pl);
							},
							observer.onCompleted,
							observer.onError
							);
					})(source);
				}
				
				return subscription;
			});
		}
		
		public static function create(type : Class, subscribeFunc : Function) : IObservable
		{
			return createWithCancelable(type, function(observer : IObserver):ICancelable
			{
				var cancelFunc : Function = subscribeFunc(observer) as Function;
				
				if (cancelFunc == null)
				{
					throw new IllegalOperationError("Expected a Function to be returned from subscribeFunc");
				}
				
				return Cancelable.create(cancelFunc);
			});
		}
		
		public static function createWithCancelable(type : Class, subscribeFunc : Function) : IObservable
		{
			return new ClosureObservable(type, function(observer : IObserver) : ICancelable
			{
				var cancelable : ICancelable = subscribeFunc(observer) as ICancelable;
				
				if (cancelable == null)
				{
					throw new IllegalOperationError("Expected an ICancelable to be returned from subscribeFunc");
				}
				
				return cancelable;
			});
		});
		
		public static function concat(type : Class, sources : Array) : IObservable
		{
			if (sources == null || sources.length == 0)
			{
				throw new ArgumentError("");
			}
			
			sources = sources.slice();
			
			return new ClosureObservable(type, function(observer : IObserver):ICancelable
			{
				var remainingSources : Array = sources.slice();
				var currentSource : IObservable = remainingSources.shift();
			
				var schedule : FutureCancelable = new FutureCancelable();
				var subscription : FutureCancelable = new FutureCancelable();
				
				var composite : CompositeCancelable = new CompositeCancelable([schedule, subscription]);

				var innerObserver : IObserver = null;
				
				innerObserver = new ClosureObserver(
					observer.onNext,
					function () : void
					{
						if (remainingSources.length > 0)
						{
							currentSource = IObservable(remainingSources.shift());
							
							subscription.innerSubscription = currentSource.subscribeWith(innerObserver);
						}
						else
						{
							observer.onCompleted();
						}
					},
					observer.onError
					);
				
				subscription.innerSubscription = currentSource.subscribeWith(innerObserver);
				
				return composite;
			});
		}
		
		public static function defer(type : Class, observableFactory:Function):IObservable
		{
			if (observableFactory == null)
			{
				throw new ArgumentError("observableFactory cannot be null");
			}
			
			return new ClosureObservable(type, function(observer : IObserver):ICancelable
			{
				var observable : IObservable = observableFactory();
				
				if (observable.type != type)
				{
					throw new ArgumentError("Deferred observable type must match type given to defer"); 
				}
				
				return observable.subscribeWith(observer);
			});
		}
		
		public static function generate(type : Class, initialState : Object, predicate : Function, resultMap : Function, 
			iterate : Function, scheduler : IScheduler = null) : IObservable
		{
			scheduler = resolveScheduler(scheduler);
			
			return new ClosureObservable(type, function(observer : IObserver) : ICancelable
			{
				var currentState : Object = initialState;
				var firstIteration : Boolean = true;
				
				var recursiveAction : Function = function(reschedule : Function):void
				{
					var useValue : Boolean = false;
					var outputValue : Object = resultMap;
					
					try
					{
						if (firstIteration)
						{
							firstIteration = !firstIteration;
						}
						else
						{
							currentState = iterate(currentState);
						}
						
						useValue = predicate(currentState);
						
						if (useValue)
						{
							outputValue = resultMap(currentState);
						}
					}
					catch(err : Error)
					{
						observer.onError(err);
						return;
					}
					
					if (useValue)
					{
						observer.onNext(outputValue);
						reschedule();
					}
					else
					{
						observer.onCompleted();
					}
				};
				
				return Scheduler.scheduleRecursive(scheduler, recursiveAction);
			});
		}
		
		public static function interval(intervalMs : uint, scheduler : IScheduler = null):IObservable
		{
			return timer(intervalMs, intervalMs, scheduler);
		}
		
		public static function timer(delayMs : uint, intervalMs : uint, scheduler : IScheduler = null):IObservable
		{
			scheduler = Observable.resolveScheduler(scheduler);
			
			return new ClosureObservable(int, function(observer : IObserver) : ICancelable
			{
				var intervalIndex : uint = 0;
				
				var scheduledAction : FutureCancelable = new FutureCancelable();
				
				scheduledAction.innerSubscription = scheduler.schedule(function():void
					{
						observer.onNext(++intervalIndex);
						
						scheduledAction.innerSubscription = Scheduler.scheduleRecursive(scheduler,
							function(recurse : Function):void
							{
								observer.onNext(++intervalIndex);
								
								recurse();
							}, intervalMs);
					}, delayMs);
				
				return scheduledAction;
			});
		}
		
		public static function join(type : Class, plans : Array) : IObservable
		{
			return new ClosureObservable(type, function(observer : IObserver) : ICancelable
			{
				var activePlans : Array = new Array().concat(plans);
				var sources : Array = new Array();
				var queues : Dictionary = new Dictionary();
				var completed : Dictionary = new Dictionary();
				
				var source : IObservable = null;
				
				for each(var plan : Plan in activePlans)
				{
					var index : int = 0;
					
					for each(source in plan.sources)
					{
						if (plan.sources.indexOf(source, (index++) + 1) != -1)
						{
							observer.onError(new ArgumentError("Sources must be unique within a plan"));
							return ClosureCancelable.empty();
						}
						
						if (queues[source] == undefined)
						{
							sources.push(source);
							queues[source] = new Array();
							completed[source] = false;
						}
					}
				}
				
				var matchPlan : Function = function():void
				{
					var match : Plan = null;
					
					for each(var plan : Plan in activePlans)
					{
						var args : Array = new Array();
						
						for each(source in plan.sources)
						{
							if (queues[source].length > 0)
							{
								args.push(queues[source][0]);
							}
							else
							{
								break;
							}
						}
						
						if (args.length == plan.sources.length)
						{
							for each(source in plan.sources)
							{
								queues[source].shift();
								
								if (completed[source] && queues[source].length == 0)
								{
									delete queues[source];
									delete completed[source];
									sources.splice(sources.indexOf(source), 1);
								}
							}
							
							var value : Object = null;
							
							try
							{
								value = plan.selector.apply(NaN, args);
							}
							catch(err : Error)
							{
								observer.onError(err);
								return;
							}
							
							observer.onNext(value);
							
							checkComplete();
							
							break;
						}
					}
				};
				
				var checkComplete : Function = function():void
				{
					var tempPlans : Array = new Array().concat(activePlans);
					
					for each(var plan : Plan in tempPlans)
					{
						for each(var source : IObservable in plan.sources)
						{
							if (!queues[source] || (completed[source] && queues[source].length == 0))
							{
								activePlans.splice(activePlans.indexOf(plan), 1);								
								break;
							}
						}
					}
					
					if (sources.length == 0 || activePlans.length == 0)
					{
						observer.onCompleted();
					}
				};
					
				var subscriptions : CompositeCancelable = new CompositeCancelable([]);
				
				var tempSources : Array = sources.concat([]);
					
				for each(source in tempSources)
				{
					(function(source:IObservable):void
					{
						var safetyObserver : SafetyObserver = new SafetyObserver(new ClosureObserver(
							function(v:Object):void
							{
								queues[source].push(v);
								matchPlan();
							},
							function():void
							{
								if (queues[source].length == 0)
								{
									delete queues[source];
									delete completed[source];
									sources.splice(sources.indexOf(source), 1);
									
									checkComplete();
								}
								else
								{
									completed[source] = true;
								}
							},
							observer.onError));
							
						var subscription : ICancelable = source.subscribeWith(safetyObserver);
						
						subscriptions.add(subscription);
						
						safetyObserver.setSubscription(subscription);
						
					})(source);
				}
				
				return subscriptions;
			});
		}
		
		public static function forkJoin(sources : Array) : IObservable
		{
			if (sources.length < 2)
			{
				throw new ArgumentError("At least two sources must be passed to forkJoin"); 
			}
			
			sources = new Array().concat(sources);
			
			return new ClosureObservable(Array, function(observer : IObserver) : ICancelable
			{
				var hasValue : Array = new Array(sources.length);
				var isComplete : Array = new Array(sources.length);
				var values : Array = new Array();
				
				var subscriptions : CompositeCancelable = new CompositeCancelable([]);
				
				var booleanPredicate : Function = function(v:Boolean, i:int, a:Array) : Boolean { return v; };
				
				for (var i:int =0;i<sources.length; i++)
				{
					(function(i:int):void
					{
						var source : IObservable = sources[i];
						
						subscriptions.add(source.subscribe(
							function(v:Object):void
							{
								values[i] = v;
								
								if (!hasValue[i])
								{
									hasValue[i] = true;
								}
							},
							function():void
							{
								isComplete[i] = true;
								
								if (isComplete.every(booleanPredicate))
								{
									if (hasValue.every(booleanPredicate))
									{
										observer.onNext(values.concat([]));
									}
									
									observer.onCompleted();
								}
							},
							observer.onError));
						
					})(i);
				}
				
				return subscriptions;
			});
		}
		
		public static function fromEvent(eventDispatcher:IEventDispatcher, type:String, eventType : Class = null, useCapture:Boolean=false, priority:int=0):IObservable
		{
			eventType = eventType || Event;
			
			if (eventDispatcher == null)
			{
				throw new ArgumentError("eventDispatcher cannot be null");
			}
			
			return new ClosureObservable(eventType, function(observer : IObserver, scheduler : IScheduler = null) : ICancelable
			{
				scheduler = Observable.resolveScheduler(scheduler);
				
				var listener : Function = function(event : Event) : void
				{
					scheduler.schedule(function():void
					{
						observer.onNext(event);
					});
				};
				
				scheduler.schedule(function():void
				{
					eventDispatcher.addEventListener(type, listener, useCapture, priority);
				});
				
				return new ClosureCancelable(function():void
				{
					eventDispatcher.removeEventListener(type, listener, useCapture);
				});
			});
		}
		
		public static function fromEvents(eventDispatcher:IEventDispatcher, types:Array, commonEventType : Class = null, useCapture:Boolean=false, priority:int=0):IObservable
		{
			return Observable.merge(commonEventType,
				Observable.fromArray(String, types)
					.selectMany(commonEventType, function(type : String) : IObservable
					{
						return fromEvent(eventDispatcher, type, commonEventType, useCapture, priority);
					}));
		}
		
		public static function fromErrorEvent(eventDispatcher:IEventDispatcher, type:String, eventType : Class = null, useCapture:Boolean=false, priority:int=0, errorMap : Function = null):IObservable
		{
			return mapErrorEvents(
				fromEvent(eventDispatcher, type, eventType, useCapture, priority),
				errorMap
			);
		}
		
		public static function fromErrorEvents(eventDispatcher:IEventDispatcher, types:Array, eventType : Class = null, useCapture:Boolean=false, priority:int=0, errorMap : Function = null):IObservable
		{
			return mapErrorEvents(
				fromEvents(eventDispatcher, types, eventType, useCapture, priority),
				errorMap
			);
		}
		
		private static function mapErrorEvents(source : IObservable, errorMap : Function = null) : IObservable
		{
			errorMap = errorMap || ErrorUtil.mapErrorEvent;
			
			return source
				.take(1)
				.selectMany(Error, function(event : Event) : IObservable
				{
					var error : Error = null;
					
					try
					{
						error = errorMap(event) as Error;
						
						if (error == null)
						{
							error = new Error("errorMap must return an instance of Error");
						}
					}
					catch(err : Error)
					{
						error = err;
					}
					
					return throwError(error);
				});
		}
		
		public static function empty(observableType : Class = null, scheduler : IScheduler = null) : IObservable
		{
			observableType = observableType || Object;
			scheduler = scheduler || ImmediateScheduler.instance;
			
			return new ClosureObservable(observableType, function(obs:IObserver) : ICancelable
			{
				return new ScheduledActionSubscription(
					scheduler.schedule(obs.onCompleted)
				);
			});
		}
		
		public static function onErrorResumeNext(sources:Array, scheduler:IScheduler=null):IObservable
		{
			if (sources == null || sources.length == 0)
			{
				throw new ArgumentError("sources");
			}
			
			scheduler = resolveScheduler(scheduler);
			
			// Make internally immutable
			sources = new Array().concat(sources);
			
			return new ClosureObservable(sources[0].type, function(obs:IObserver) : ICancelable
			{
				var remainingSources : Array = new Array().concat(sources);
				
				var subscription : ICancelable = null;
				var futureSubscription : FutureCancelable = new FutureCancelable();
				
				var scheduledAction : ICancelable = null;
				
				var moveNextFunc : Function = null;
				
				moveNextFunc = function():void
				{
					var currentSource : IObservable = remainingSources.shift();
					
					if (subscription != null)
					{
						subscription.cancel();
					}
					
					subscription = currentSource.subscribe(
						function(pl:Object) : void { obs.onNext(pl); },
						function() : void
						{
							if (remainingSources.length > 0)
							{
								scheduledAction = scheduler.schedule(moveNextFunc);
							}
							else
							{
								obs.onCompleted();
							}
						},
						function(e:Error) : void
						{
							if (remainingSources.length > 0)
							{
								scheduledAction = scheduler.schedule(moveNextFunc);
							}
							else
							{
								obs.onError(e);
							}
						});
					
					futureSubscription.innerSubscription = subscription;
				};
				
				scheduledAction = scheduler.schedule(moveNextFunc);
				
				return new ClosureCancelable(function():void
				{
					if (scheduledAction != null)
					{
						scheduledAction.cancel();
					}
					
					if (futureSubscription != null)
					{
						futureSubscription.cancel();
					}
				});
			});
		}
		
		/**
		 * Returns an IObservable that never completes
		 */		
		public static function never(observableType : Class = null) : IObservable
		{
			observableType = observableType || Object;
			
			return new ClosureObservable(observableType, function(obs:IObserver) : ICancelable
			{
				return new ClosureCancelable(function():void{});
			});
		}
		
		public static function uncaughtErrors(loaderInfo : LoaderInfo = null) : IObservable
		{
			return Observable.merge(Error, Observable.fromArray(Error, 
				[_unhandledErrorsSubject, getNativeUncaughtErrors(loaderInfo)]));
		}
		
		private static function getNativeUncaughtErrors(loaderInfo : LoaderInfo = null) : IObservable
		{
			loaderInfo = loaderInfo || LoaderInfo.getLoaderInfoByDefinition(Observable);
			
			var uncaughtErrorsSupported : Boolean = 
				loaderInfo.hasOwnProperty("uncaughtErrorEvents");
			
			if (uncaughtErrorsSupported)
			{
				return fromEvent(
					IEventDispatcher(loaderInfo["uncaughtErrorEvents"]),
					"uncaughtError"
					);
			}
			else
			{
				return never();
			}
		}
		
		public static function range(start : int, count : uint, scheduler : IScheduler = null) : IObservable
		{
			scheduler = Observable.resolveScheduler(scheduler);
			
			if (count < 0)
			{
				throw new RangeError("count must be > 0");
			}
			
			var end : int = start + count;
			
			return generate(int, start,
				function(i:int):Boolean { return i<end; },
				function(i:int):int { return i; },
				function(i:int):int { return i+1; },
				scheduler
				);
		}
		
		public static function throwError(error : Error, observableType : Class = null) : IObservable
		{
			if (error == null)
			{
				throw new ArgumentError("error cannot be null");
			}
			
			observableType = observableType || Object;
			
			return new ClosureObservable(observableType, function(obs:IObserver) : ICancelable
			{
				obs.onError(error);
				
				return new ClosureCancelable(function():void{});
			});
		}
		
		public static function fromArray(elementType : Class, values : Array, scheduler : IScheduler = null) : IObservable
		{
			scheduler = resolveScheduler(scheduler);
			
			values = values.slice();
			
			return Observable.generate(elementType,
				0,
				function(i : int):Boolean { return i < values.length; },
				function(i : int):Object { return values[i]; },
				function(i : int):int { return i+1; },
				scheduler);
		}
		
		public static function returnValue(type : Class, value : Object, scheduler : IScheduler = null) : IObservable
		{
			return fromArray(type, [value], scheduler); 
		}
		
		public static function catchErrors(sources : Array, scheduler : IScheduler = null) : IObservable
		{
			if (sources == null || sources.length == 0)
			{
				throw new ArgumentError("sources");
			}
			
			scheduler = resolveScheduler(scheduler);
			
			// Make internally immutable
			sources = new Array().concat(sources);
			
			return new ClosureObservable(sources[0].type, function(obs:IObserver) : ICancelable
			{
				var remainingSources : Array = new Array().concat(sources);
				
				var subscription : ICancelable = null;
				var scheduledAction : ICancelable = null;
				
				var moveNextFunc : Function = null;
				
				moveNextFunc = function():void
				{
					var currentSource : IObservable = remainingSources.shift();
						
					subscription = currentSource.subscribe(
						function(pl:Object) : void { obs.onNext(pl); },
						function() : void { obs.onCompleted(); },
						function(e:Error) : void
						{
							if (remainingSources.length > 0)
							{
								scheduledAction = scheduler.schedule(moveNextFunc);
							}
							else
							{
								obs.onError(e);
							}
						});
				};
				
				scheduledAction = scheduler.schedule(moveNextFunc);
				
				return new ClosureCancelable(function():void
				{
					if (scheduledAction != null)
					{
						scheduledAction.cancel();
					}
					
					if (subscription != null)
					{
						subscription.cancel();
					}
				});
			});
		}
		
		public static function resolveScheduler(scheduler : IScheduler) : IScheduler
		{
			return scheduler || Scheduler.defaultScheduler;
		}		
		
		public static function merge(type : Class, source : IObservable, scheduler : IScheduler = null) : IObservable
		{
			if (source.type != IObservable)
			{
				throw new ArgumentError("merge can only merge an IObservable of IObservables");
			}
			
			scheduler = resolveScheduler(scheduler);
			
			return new ClosureObservable(type, function(obs:IObserver) : ICancelable
			{
				var subscription : CompositeCancelable = new CompositeCancelable([]);
				
				var sourceComplete : Boolean = false;
				
				var outerSubscription : FutureCancelable = new FutureCancelable();
				subscription.add(outerSubscription);
				
				outerSubscription.innerSubscription = source.subscribe(
					function(innerSource:IObservable) : void
					{
						if (innerSource == null)
						{
							throw new IllegalOperationError("Cannot merge null IObservable");
						}
						
						var innerSubscription : FutureCancelable = new FutureCancelable();
						subscription.add(innerSubscription);
						
						innerSubscription.innerSubscription = innerSource.subscribe(
							function(pl:Object) : void
							{
								obs.onNext(pl);
							},
							function() : void
							{
								innerSubscription.cancel();
								subscription.remove(innerSubscription);
								
								if (sourceComplete && subscription.count == 0)
								{
									obs.onCompleted();
								}
							},
							obs.onError
						);
					},
					function() : void
					{
						sourceComplete = true;
						
						subscription.remove(outerSubscription);
						
						if (subscription.count == 0)
						{
							obs.onCompleted();
						}
					},
					obs.onError
					);
				
				return subscription;
			});
		}
		
		public static function start(action : Function, type : Class = null, scheduler : IScheduler = null) : IObservable
		{
			return toAsync(action, type, scheduler)();
		}
		
		public static function toAsync(action : Function, type : Class = null, scheduler : IScheduler = null) : Function
		{
			scheduler = scheduler || Scheduler.asynchronous;
			
			var hasReturnType : Boolean = (type != null);
			
			type = type || Unit;
			
			return function (... args) : IObservable
			{
				return new ClosureObservable(type, function(obs:IObserver) : ICancelable
				{
					var scheduledAction : ICancelable = scheduler.schedule(function():void
					{
						try
						{
							var ret : Object = action();
						}
						catch(err : Error)
						{
							obs.onError(err);
							return;
						}
						
						if (hasReturnType)
						{
							obs.onNext(ret);
						}
						obs.onCompleted();
					});
					
					return new ScheduledActionSubscription(scheduledAction);
				});
			};
		}
		
		public static function loader(request : URLRequest, loaderContext : LoaderContext = null) : ITaskObservable
		{
			var progress : Subject = new Subject(int);
			
			var connection : IObservable = new ClosureObservable(Object, function(observer : IObserver) : ICancelable
			{
				var loader : Loader = new Loader();
				loader.load(request, loaderContext);

				try
				{
					loader.load(request);
				}
				catch(err : Error)
				{
					observer.onError(err);
					return ClosureCancelable.empty();
				}
				
				progress.onNext(0);
				
				return new CompositeCancelable([
					Observable.fromEvent(loader.loaderInfo, ProgressEvent.PROGRESS)
						.subscribe(function(progressEvent : ProgressEvent):void
						{
							if (progressEvent.bytesTotal == 0)
							{
								progress.onNext(0);
							}
							else
							{
								progress.onNext(progressEvent.bytesLoaded / progressEvent.bytesTotal);
							}
						}),
					Observable.fromEvent(loader.loaderInfo, Event.COMPLETE)
						.subscribe(function(completeEvent : Event) : void
						{
							observer.onNext(loader.data);
							observer.onCompleted();
						}),
					Observable.fromErrorEvents(loader.loaderInfo, 
						[IOErrorEvent.IO_ERROR, SecurityErrorEvent.SECURITY_ERROR])
						.subscribeWith(observer)
				]);

			});
			
			return new TaskObservable(connection, progress);
		}
		
		public static function urlLoader(request : URLRequest, dataFormat : String = "text", loaderContext : LoaderContext = null) : ITaskObservable
		{
			var progress : Subject = new Subject(int);
			
			var connection : IObservable = new ClosureObservable(Object, function(observer : IObserver) : ICancelable
			{
				var loader : URLLoader = new URLLoader();
				
				try
				{
					loader.load(request);
				}
				catch(err : Error)
				{
					observer.onError(err);
					return ClosureCancelable.empty();
				}
				
				progress.onNext(0);
				
				return new CompositeCancelable([
					Observable.fromEvent(loader, ProgressEvent.PROGRESS)
						.subscribe(function(progressEvent : ProgressEvent):void
						{
							if (progressEvent.bytesTotal == 0)
							{
								progress.onNext(0);
							}
							else
							{
								progress.onNext(progressEvent.bytesLoaded / progressEvent.bytesTotal);
							}
						}),
					Observable.fromEvent(loader, Event.COMPLETE)
						.subscribe(function(completeEvent : Event) : void
						{
							observer.onNext(loader.data);
							observer.onCompleted();
						}),
					Observable.fromErrorEvents(loader, 
						[IOErrorEvent.IO_ERROR, SecurityErrorEvent.SECURITY_ERROR])
						.subscribeWith(observer)
				]);

			});
			
			return new TaskObservable(connection, progress);
		}
		
		CONFIG::FLEX
		{
			public static function fromCollection(elementType : Class, collection : ICollectionView, scheduler : IScheduler	= null) : IObservable
			{
				return defer(elementType, function():IObservable
				{
					return fromViewCursor(elementType, collection.createCursor());
				});
			}
			
			public static function fromViewCursor(elementType : Class, cursor : IViewCursor, scheduler : IScheduler	= null) : IObservable
			{
				return Observable.generate(elementType,
					true,
					function(state : Boolean):Boolean { return state; },
					function(state : Boolean):Object { return cursor.current; },
					function(state : Boolean):Boolean { return cursor.moveNext(); },
					scheduler);
			}
			
			public static function fromAsyncPattern(returnType : Class, asyncMethod : Function, 
				args : Array) : IObservable 
			{
				return defer(returnType, function():IObservable
				{
					// TODO: Catch/rethrow type coercion error here?
					var token : AsyncToken = asyncMethod.apply(NaN, args);
					
					var responder : IObservableResponder = responder(returnType);
					token.addResponder(responder);
					
					return responder;
				});
			}
			
			public static function responder(type : Class) : IObservableResponder
			{
				return new ObservableResponder(type);
			}
		}
	}
}
