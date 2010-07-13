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
	import rx.scheduling.*;
	import rx.util.ErrorUtil;

	/**
	 * Provides static methods that create observable sequences
	 */
	public class Observable
	{
		private static var _unhandledErrorsSubject : Subject = new Subject(Error);
		
		public function Observable()
		{
			throw new IllegalOperationError("This class is static and cannot be instantiated. Create an IObservable by using one of Observable's static methods");
		}
		
		/**
		 * Takes multiple source sequences and returns values from the first sequence to emit a value  
		 * @param sources The sources that will be subscribed to
		 * @return An observable sequence of the same valueClass as the first sequence in sources
		 */		
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
					
						futureSubscription.innerCancelable = obs.subscribe(
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
		
		/**
		 * Defers selection of the sequence to use by using a function that returns a key into a dictionary of sequences 
		 * @param valueClass The valueClass of the return sequence
		 * @param keySelector The function that, at the moment of subscription, will return the key into dictionary
		 * @param dictionary The dictionary of sequences
		 * @return An observable sequence of valueClass
		 */		
		public static function lookup(valueClass : Class, keySelector : Function, dictionary : Dictionary) : IObservable
		{
			if (valueClass == null) throw new ArgumentError("valueClass cannot be null");
			if (dictionary == null) throw new ArgumentError("dictionary cannot be null");
			if (keySelector == null) throw new ArgumentError("keySelector cannot be null");
			
			return defer(valueClass, function():IObservable
			{
				var key : Object = null;
				
				try
				{
					key = keySelector();
				}
				catch(err : Error)
				{
					return Observable.throwError(err, valueClass);
				}
				
				var value : Object = dictionary[key];
				
				if (value == undefined)
				{
					return Observable.empty(valueClass);
				}
				
				var sequence : IObservable = value as IObservable;
				
				if (sequence == null)
				{
					var error : Error = new IllegalOperationError("lookup dictionary value for " + (key||"null") + 
						" was not an IObservable");
						
					return Observable.throwError(error, valueClass);
				}
				
				return sequence;
			});
		}
		
		/**
		 * Creates a custom observable sequence 
		 * @param valueClass The valueClass of the created sequence 
		 * @param subscribeFunc The function that will be executed when a subscriber subscribes, the return value of which is a function to be run when the sequence is terminated
		 * @return An observable sequence of valueClass
		 */
		public static function create(valueClass : Class, subscribeFunc : Function) : IObservable
		{
			return createWithCancelable(valueClass, function(observer : IObserver):ICancelable
			{
				var cancelFunc : Function = subscribeFunc(observer) as Function;
				
				if (cancelFunc == null)
				{
					throw new ArgumentError("Expected a Function to be returned from subscribeFunc");
				}
				
				return Cancelable.create(cancelFunc);
			});
		}
		
		/**
		 * Creates a custom observable sequence that uses cancelable resources 
		 * @param valueClass The valueClass of the created sequence 
		 * @param subscribeFunc The function that will be executed when a subscriber subscribes, the return value of which is an ICancelable to be canceled when the sequence is terminated
		 * @return An observable sequence of valueClass
		 */
		public static function createWithCancelable(valueClass : Class, subscribeFunc : Function) : IObservable
		{
			return new ClosureObservable(valueClass, function(observer : IObserver) : ICancelable
			{
				var cancelable : ICancelable = subscribeFunc(observer) as ICancelable;
				
				if (cancelable == null)
				{
					throw new ArgumentError("Expected an ICancelable to be returned from subscribeFunc");
				}
				
				return cancelable;
			});
		}
		
		/**
		 * Concatonates multiple sequences by running each sequence as the previous one finishes 
		 * @param valueClass The class common to all sequences in sources
		 * @param sources The sequences to concatonate
		 * @return An observable sequence of valueClass
		 */		
		public static function concat(valueClass : Class, sources : Array) : IObservable
		{
			if (sources == null || sources.length == 0)
			{
				throw new ArgumentError("");
			}
			
			sources = sources.slice();
			
			return new ClosureObservable(valueClass, function(observer : IObserver):ICancelable
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
							
							subscription.innerCancelable = currentSource.subscribeWith(innerObserver);
						}
						else
						{
							observer.onCompleted();
						}
					},
					observer.onError
					);
				
				subscription.innerCancelable = currentSource.subscribeWith(innerObserver);
				
				return composite;
			});
		}
		
		/**
		 * Defers selection of a sequence until the sequence is subscribed to  
		 * @param valueClass The valueClass of the returned sequence
		 * @param observableFactory The function that will be executed when a new subscription occurs, the returned sequence will be used for the subscriber.
		 * @return An observable sequence of valueClass
		 */		
		public static function defer(valueClass : Class, observableFactory:Function):IObservable
		{
			if (observableFactory == null)
			{
				throw new ArgumentError("observableFactory cannot be null");
			}
			
			return new ClosureObservable(valueClass, function(observer : IObserver):ICancelable
			{
				var observable : IObservable = observableFactory();
				
				if (observable.valueClass != valueClass)
				{
					throw new ArgumentError("Deferred observable valueClass must match valueClass given to defer"); 
				}
				
				return observable.subscribeWith(observer);
			});
		}
		
		/**
		 * Creates a custom observable sequence that is controlled by methods supplied as arguments 
		 * @param valueClass The valueClass of values emitted by the sequence
		 * @param initialState The initial state value to use (of class valueClass)
		 * @param predicate The predicate to determine whether the sequence has completed
		 * @param iterate The function executed between iterations
		 * @param resultMap The function that maps the current state to an output value
		 * @param scheduler The scheduler used to control flow
		 * @return An observable sequence of valueClass
		 */		
		public static function generate(valueClass : Class, initialState : Object, predicate : Function, iterate : Function, 
			resultMap : Function, scheduler : IScheduler = null) : IObservable
		{
			scheduler = scheduler || Scheduler.synchronous;
			
			return new ClosureObservable(valueClass, function(observer : IObserver) : ICancelable
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
		
		/**
		 * Defers selection of one of two sequences until the sequence is subscribed to
		 * @param valueClass The valueClass of the returned sequence
		 * @param predicate The function to execute when a subscription occurs to determine which sequence to subscribe to
		 * @param ifTrue The sequence to subscribe to if predicate returns true
		 * @param ifFalse The sequence to subscribe to if predicate returns false
		 * @return An observable sequence of valueClass
		 */
		public static function ifElse(valueClass : Class, predicate : Function, ifTrue : IObservable, ifFalse : IObservable) : IObservable
		{
			return defer(valueClass, function():IObservable
			{
				try
				{
					return (predicate())
						? ifTrue
						: ifFalse;
				}
				catch(err : Error)
				{
					return Observable.throwError(err, valueClass);
				}
				
				// Compiler bug workaround
				return null;
			});
		}
		
		/**
		 * Creates an unending observable sequence of integers that are incremented at a regular interval 
		 * @param intervalMs The interval, in milliseconds, to wait in between values
		 * @param scheduler The scheduler used for timing
		 * @return An observable sequence of int
		 */
		public static function interval(intervalMs : uint, scheduler : IScheduler = null):IObservable
		{
			return timer(intervalMs, intervalMs, scheduler);
		}
		
		/**
		 * Creates an unending observable sequence of integers that begin after a delay and are incremented at a regular interval 
		 * @param delayMs The interval, in milliseconds, to wait before the first value
		 * @param intervalMs The interval, in milliseconds, to wait in between subsequent values
		 * @param scheduler The scheduler used for timing
		 * @return An observable sequence of int
		 */
		public static function timer(delayMs : uint, intervalMs : uint, scheduler : IScheduler = null):IObservable
		{
			scheduler = scheduler || Scheduler.synchronous;
			
			return new ClosureObservable(int, function(observer : IObserver) : ICancelable
			{
				var intervalIndex : uint = 0;
				
				var scheduledAction : FutureCancelable = new FutureCancelable();
				
				scheduledAction.innerCancelable = scheduler.schedule(function():void
					{
						observer.onNext(++intervalIndex);
						
						scheduledAction.innerCancelable = Scheduler.scheduleRecursive(scheduler,
							function(recurse : Function):void
							{
								observer.onNext(++intervalIndex);
								
								recurse();
							}, intervalMs);
					}, delayMs);
				
				return scheduledAction;
			});
		}
		
		/**
		 * Matches join multiple plans (source sequence combinations) in the order they are specified 
		 * @param valueClass The common value class shared between the output of all plans in plans 
		 * @param plans The array of rx.Plan objects creates using 'and' and 'then'
		 * @return An observable sequence of valueClass
		 */		
		public static function join(valueClass : Class, plans : Array) : IObservable
		{
			return new ClosureObservable(valueClass, function(observer : IObserver) : ICancelable
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
		
		/**
		 * Subscribes to multiple source sequence and emits the last values of each after all have completed 
		 * @param sources The sequences to subscribe to
		 * @return An observable sequence of Array
		 */		
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
		
		/**
		 * Creates a sequence of events from an IEventDispatcher 
		 * @param eventDispatcher The IEventDispatcher that dispatches the event
		 * @param valueClass The event valueClass name
		 * @param eventType The valueClass of event dispatched by eventDispatcher. Event will be used if this argument is null.
		 * @param useCapture Whether to pass useCapture when subscribing to and unsubscribing from the event
		 * @param priority The priority of the event
		 * @return An observable sequence of eventType, or Event if eventType is null
		 */		
		public static function fromEvent(eventDispatcher:IEventDispatcher, eventType:String, valueClass : Class = null, useCapture:Boolean=false, priority:int=0):IObservable
		{
			valueClass = valueClass || Event;
			
			if (eventDispatcher == null)
			{
				throw new ArgumentError("eventDispatcher cannot be null");
			}
			
			return new ClosureObservable(valueClass, function(observer : IObserver, scheduler : IScheduler = null) : ICancelable
			{
				scheduler = scheduler || Scheduler.synchronous;
				
				var listener : Function = function(event : Event) : void
				{
					scheduler.schedule(function():void
					{
						observer.onNext(event);
					});
				};
				
				scheduler.schedule(function():void
				{
					eventDispatcher.addEventListener(eventType, listener, useCapture, priority);
				});
				
				return new ClosureCancelable(function():void
				{
					eventDispatcher.removeEventListener(eventType, listener, useCapture);
				});
			});
		}
		
		/**
		 * Creates Combines events from multiple event valueClasss 
		 * @param eventDispatcher The IEventDispatcher that dispatches the event
		 * @param valueClasss An array event valueClass names
		 * @param commonEventType The valueClass of event common to all events. Event will be used if this argument is null.
		 * @param useCapture Whether to pass useCapture when subscribing to and unsubscribing from the event
		 * @param priority The priority of the event
		 * @return An observable sequence of commonEventType, or Event if commonEventType is null 
		 */
		public static function fromEvents(eventDispatcher:IEventDispatcher, valueClasss:Array, commonEventType : Class = null, useCapture:Boolean=false, priority:int=0):IObservable
		{
			return Observable.merge(commonEventType,
				Observable.fromArray(String, valueClasss)
					.selectMany(commonEventType, function(valueClass : String) : IObservable
					{
						return fromEvent(eventDispatcher, valueClass, commonEventType, useCapture, priority);
					}));
		}
		
		/**
		 * Creates a sequence that emits an error when an event is received from an IEventDispatcher  
		 * @param valueClass The valueClass for the output sequence
		 * @param eventDispatcher The IEventDispatcher that dispatches the event
		 * @param valueClass The event valueClass name
		 * @param useCapture Whether to pass useCapture when subscribing to and unsubscribing from the event
		 * @param priority The priority of the event
		 * @param errorMap The function that maps an event to an Error. null can be used if the event will be ErrorEvent
		 * @return An observable sequence of commonEventType, or Event if commonEventType is null 
		 */
		public static function fromErrorEvent(valueClass : Class, eventDispatcher:IEventDispatcher, eventType:String, useCapture:Boolean=false, priority:int=0, errorMap : Function = null):IObservable
		{
			return mapErrorEvents(
				fromEvent(eventDispatcher, eventType, valueClass, useCapture, priority),
				errorMap
			);
		}
		
		/**
		 * Creates a sequence that emits an error when one of several event valueClasss is received from an IEventDispatcher
		 * @param valueClass The valueClass for the output sequence
		 * @param eventDispatcher The IEventDispatcher that dispatches the event
		 * @param valueClasss The event valueClasss that signify an error
		 * @param useCapture Whether to pass useCapture when subscribing to and unsubscribing from the event
		 * @param priority The priority of the event
		 * @param errorMap The function that maps an event to an Error. null can be used if the event will be ErrorEvent
		 * @return An observable sequence of 
		 */		
		public static function fromErrorEvents(valueClass : Class, eventDispatcher:IEventDispatcher, valueClasss:Array, useCapture:Boolean=false, priority:int=0, errorMap : Function = null):IObservable
		{
			return mapErrorEvents(
				fromEvents(eventDispatcher, valueClasss, Event, useCapture, priority),
				errorMap
			)
			.ofType(valueClass);
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
		
		/**
		 * Creates a sequence that immediately completes  
		 * @param observableType The value class for the sequence
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of observableType
		 */		
		public static function empty(observableType : Class = null, scheduler : IScheduler = null) : IObservable
		{
			observableType = observableType || Object;
			scheduler = scheduler || ImmediateScheduler.instance;
			
			return new ClosureObservable(observableType, function(obs:IObserver) : ICancelable
			{
				return scheduler.schedule(obs.onCompleted);
			});
		}
		
		/**
		 * Concatonates a list of sequence as each one errors or complete 
		 * @param sources The list of sequences to concatonate
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of the valueClass of the value sequence in sources
		 */		
		public static function onErrorResumeNext(sources:Array, scheduler:IScheduler=null):IObservable
		{
			if (sources == null || sources.length == 0)
			{
				throw new ArgumentError("sources");
			}
			
			scheduler = scheduler || Scheduler.synchronous;
			
			// Make internally immutable
			sources = new Array().concat(sources);
			
			return new ClosureObservable(sources[0].valueClass, function(obs:IObserver) : ICancelable
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
					
					futureSubscription.innerCancelable = subscription;
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
		
		/**
		 * Creates a sequences that accesses uncaught errors if supported by the platform (Flash Player 10.1+)
		 * @param loaderInfo The LoaderInfo to catch uncaught errors from, or the LoaderInfo into which rx.Observable was loaded if the argument is null
		 * @return An observable sequence of errors
		 * 
		 */		
		public static function uncaughtErrors(loaderInfo : LoaderInfo = null) : IObservable
		{
			return Observable.merge(Error, Observable.fromArray(IObservable, 
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
		
		/**
		 * Creates a sequence of consecutive integers  
		 * @param start The inclusive start value of the range
		 * @param count The number of values, including start, to emit
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of int
		 */		
		public static function range(start : int, count : uint, scheduler : IScheduler = null) : IObservable
		{
			scheduler = scheduler || Scheduler.synchronous;
			
			if (count < 0)
			{
				throw new RangeError("count must be > 0");
			}
			
			var end : int = start + count;
			
			return generate(int, start,
				function(i:int):Boolean { return i<end; },
				function(i:int):int { return i+1; },
				function(i:int):int { return i; },
				scheduler
				);
		}
		
		/**
		 * Creates a sequence that immediately throws an Error  
		 * @param error The error to raise when a new subscription occurs
		 * @param observableType The valueClass of the returned sequence
		 * @return An observable sequence of observableType
		 */		
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
		
		/**
		 * Creates a sequence consisting of the values in an Array 
		 * @param elementType The class common to all values in values
		 * @param values The array of values to iterate through
		 * @param scheduler The scheduler used to control flow
		 * @return An observable sequence of elementType
		 */
		public static function fromArray(elementType : Class, values : Array, scheduler : IScheduler = null) : IObservable
		{
			scheduler = scheduler || Scheduler.synchronous;
			
			values = values.slice();
			
			return Observable.generate(elementType,
				0,
				function(i : int):Boolean { return i < values.length; },
				function(i : int):int { return i+1; },
				function(i : int):Object { return values[i]; },
				scheduler);
		}
		
		/**
		 * Repeats a value a specification number of times 
		 * @param valueClass The valueClass of the sequence and of value
		 * @param value The value to repeat
		 * @param repeatCount The number of times to emit the value
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of valueClass
		 */
		public static function repeatValue(valueClass : Class, value : Object, repeatCount : uint = 0, scheduler : IScheduler = null) : IObservable
		{
			return returnValue(valueClass, value, scheduler)
				.repeat(repeatCount);
		}
		
		/**
		 * Create a sequence consisting of exactly one value 
		 * @param valueClass The valueClass of the sequence and of value
		 * @param value The value to emit
		 * @param scheduler The scheduler to use to control flow
		 * @return An observable sequence of valueClass
		 */		
		public static function returnValue(valueClass : Class, value : Object, scheduler : IScheduler = null) : IObservable
		{
			return fromArray(valueClass, [value], scheduler); 
		}
		
		/**
		 * Concatonates a list of sequences as each one errors. A successful sequence ends the concatonation.  
		 * @param sources The list of sequence to concatonate.
		 * @param scheduler The scheduler used to control flow
		 * @return An observable sequence with the valueClass of the first sequence in sources
		 */		
		public static function catchErrors(sources : Array, scheduler : IScheduler = null) : IObservable
		{
			if (sources == null || sources.length == 0)
			{
				throw new ArgumentError("sources");
			}
			
			scheduler = scheduler || Scheduler.synchronous;
			
			// Make internally immutable
			sources = new Array().concat(sources);
			
			return new ClosureObservable(sources[0].valueClass, function(obs:IObserver) : ICancelable
			{
				var remainingSources : Array = new Array().concat(sources);
				
				var subscription : FutureCancelable = new FutureCancelable();
				var scheduledAction : FutureCancelable = new FutureCancelable();
				
				var moveNextFunc : Function = null;
				
				moveNextFunc = function():void
				{
					var currentSource : IObservable = remainingSources.shift();
						
					subscription.innerCancelable = currentSource.subscribe(
						function(pl:Object) : void { obs.onNext(pl); },
						function() : void { obs.onCompleted(); },
						function(e:Error) : void
						{
							if (remainingSources.length > 0)
							{
								scheduledAction.innerCancelable = scheduler.schedule(moveNextFunc);
							}
							else
							{
								obs.onError(e);
							}
						});
				};
				
				scheduledAction.innerCancelable = scheduler.schedule(moveNextFunc);
				
				return new CompositeCancelable([scheduledAction, subscription]);
			});
		}
		
		/**
		 * Emits the values from multiple sources in the order that they arrive 
		 * @param valueClass The valueClass common to all sequences emitted by source
		 * @param source An IObservable with valueClass IObservable, the values of which will be merged
		 * @param scheduler The scheduler used to control flow
		 * @return An observable sequence of valueClass
		 */		
		public static function merge(valueClass : Class, source : IObservable, scheduler : IScheduler = null) : IObservable
		{
			if (source.valueClass != IObservable)
			{
				throw new ArgumentError("merge can only merge an IObservable of IObservables");
			}
			
			return new ClosureObservable(valueClass, function(obs:IObserver) : ICancelable
			{
				var subscription : CompositeCancelable = new CompositeCancelable([]);
				
				var sourceComplete : Boolean = false;
				
				var outerSubscription : FutureCancelable = new FutureCancelable();
				subscription.add(outerSubscription);
				
				outerSubscription.innerCancelable = source.subscribe(
					function(innerSource:IObservable) : void
					{
						if (innerSource == null)
						{
							throw new IllegalOperationError("Cannot merge null IObservable");
						}
						
						var innerSubscription : FutureCancelable = new FutureCancelable();
						subscription.add(innerSubscription);
						
						innerSubscription.innerCancelable = innerSource.subscribe(
							obs.onNext,
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
		
		/**
		 * Creates a sequence based on a call to a function  
		 * @param action The function to call
		 * @param valueClass The valueClass of the sequence
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of valueClass
		 */		
		public static function start(action : Function, valueClass : Class = null, scheduler : IScheduler = null) : IObservable
		{
			return toAsync(action, valueClass, scheduler)();
		}
		
		/**
		 * Converts a function into an observable sequence  
		 * @param action The function to call
		 * @param valueClass The valueClass of the sequence
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of valueClass
		 */		
		public static function toAsync(action : Function, valueClass : Class = null, scheduler : IScheduler = null) : Function
		{
			scheduler = scheduler || Scheduler.asynchronous;
			
			var hasReturnType : Boolean = (valueClass != null);
			
			valueClass = valueClass || Unit;
			
			return function (... args) : IObservable
			{
				return new ClosureObservable(valueClass, function(obs:IObserver) : ICancelable
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
					
					return scheduledAction;
				});
			};
		}
		
		/**
		 * Creates an observable sequence that loads an object from a URLRequest 
		 * @param request The URLRequest to load
		 * @param loaderContext The optional LoaderContext to use
		 * @return An observable sequence of Object
		 */
		public static function loader(request : URLRequest, loaderContext : LoaderContext = null) : IObservable
		{
			var progress : Subject = new Subject(int);
			
			return new ClosureObservable(Object, function(observer : IObserver) : ICancelable
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
					Observable.fromErrorEvents(Event, loader.loaderInfo, 
						[IOErrorEvent.IO_ERROR, SecurityErrorEvent.SECURITY_ERROR])
						.subscribeWith(observer)
				]);

			});
		}
		
		/**
		 * Creates an observable sequence that loads an object from a URLRequest 
		 * @param request The URLRequest to load
		 * @param dataFormat A value of flash.net.URLLoaderDataFormat
		 * @param loaderContext The optional LoaderContext to use
		 * @return An observable sequence of Object
		 */
		public static function urlLoader(request : URLRequest, dataFormat : String = "text", loaderContext : LoaderContext = null) : IObservable
		{
			var progress : Subject = new Subject(int);
			
			return new ClosureObservable(Object, function(observer : IObserver) : ICancelable
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
					Observable.fromErrorEvents(Event, loader, 
						[IOErrorEvent.IO_ERROR, SecurityErrorEvent.SECURITY_ERROR])
						.subscribeWith(observer)
				]);

			});
		}
		
		//CONFIG::FLEX
		//{
			/**
			 * Creates a sequence consisting of the values in a collection 
			 * @param elementType The class common to all values in values
			 * @param values The collection of values to iterate through
			 * @param scheduler The scheduler used to control flow
			 * @return An observable sequence of elementType
			 */
			public static function fromCollection(elementType : Class, collection : ICollectionView, scheduler : IScheduler	= null) : IObservable
			{
				return defer(elementType, function():IObservable
				{
					return fromViewCursor(elementType, collection.createCursor());
				});
			}
			
			/**
			 * Creates a sequence consisting of the values in a view cursor 
			 * @param elementType The class common to all values in values
			 * @param values The view cursor of values to iterate through
			 * @param scheduler The scheduler used to control flow
			 * @return An observable sequence of elementType
			 */
			public static function fromViewCursor(elementType : Class, cursor : IViewCursor, scheduler : IScheduler	= null) : IObservable
			{
				return Observable.generate(elementType,
					true,
					function(state : Boolean):Boolean { return state; },
					function(state : Boolean):Boolean { return cursor.moveNext(); },
					function(state : Boolean):Object { return cursor.current; },
					scheduler);
			}
			
			/**
			 * Creates an observable sequence from a function that returns an AsyncToken 
			 * @param returnType The class of the value returned by the AsyncToken
			 * @param asyncMethod The method to execute when a new subscription occurs. This method must return AsyncToken
			 * @param args The arguments to supply to asyncMethod
			 * @return An observable sequence of returnType
			 */			
			public static function fromAsyncPattern(returnType : Class, asyncMethod : Function, 
				args : Array) : IObservable 
			{
				return defer(returnType, function():IObservable
				{
					// TODO: Catch/rethrow valueClass coercion error here?
					var token : AsyncToken = asyncMethod.apply(NaN, args);
					
					var responder : IObservableResponder = responder(returnType);
					token.addResponder(responder);
					
					return responder;
				});
			}
			
			/**
			 * Creates an observable sequence that is also an IResponder 
			 * @param valueClass The valueClass of the returned sequence
			 * @return An observable sequence of valueClass
			 */			
			public static function responder(valueClass : Class) : IObservableResponder
			{
				return new ObservableResponder(valueClass);
			}
		//}
	}
}
