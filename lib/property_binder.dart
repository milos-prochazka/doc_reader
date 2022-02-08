import 'package:flutter/widgets.dart';

class PropertyBinder extends InheritedWidget
{
  final events = <PropertyOnChange>[];
  final properties = <String, BindableProperty>{};

  PropertyBinder({Key? key, required BuildContext context, required WidgetBuilder builder})
  : super(key: key, child: Builder(builder: builder));

  /// Nastaveni property
  /// * Kontroluje zda se meni hodnota property.
  /// * Pokud ano nastavi novou hodnotu a vyvola handlery udalosti.
  ///  **Parametry**
  /// - [key] Nazev property
  /// - [value] Hodnota property
  void setProperty(String key, dynamic value)
  {
    if (!properties.containsKey(key))
    {
      properties[key] = BindableProperty(key, value);
    }
    else
    {
      properties[key]?.setValue(this, value);
    }
  }

  /// Nucene nastaveni property
  /// * Nekontroluje se zmena hodnoty property.
  /// * Vzdy se vyvolaji handlery udalosti.
  /// * Mozno vyuzit k vysilani zprav do handleru udalosti.
  /// **Parametry**
  /// * [key] Nazev property
  /// * [value] Hodnota property
  void forceProperty(String key, dynamic value)
  {
    if (!properties.containsKey(key))
    {
      properties[key] = BindableProperty(key, value);
    }
    else
    {
      properties[key]?.forceValue(this, value);
    }
  }

  //
  void _setOnChange(String? key, PropertyOnChange onChange)
  {
    if (key == null)
    {
      if (!events.contains(onChange))
      {
        events.add(onChange);
      }
    }
    else
    {
      BindableProperty prop;
      if (!properties.containsKey(key))
      {
        prop = BindableProperty(key, null);
        properties[key] = prop;
      }
      else
      {
        prop = properties[key]!;
      }

      if (!prop.events.contains(onChange))
      {
        prop.events.add(onChange);
      }
    }
  }

  void _removeOnChange(String? key, PropertyOnChange onChange)
  {
    if (key == null)
    {
      if (events.contains(onChange))
      {
        events.remove(onChange);
      }
    }
    else
    {
      if (properties.containsKey(key))
      {
        final prop = BindableProperty(key, null);
        if (prop.events.contains(onChange))
        {
          prop.events.remove(onChange);
        }
      }
    }
  }

  /// Odstraneni property
  void removeProperty(String key)
  {
    properties.remove(key);
  }

  /// Cteni property jako dynamic objekt
  dynamic getPropertyDynamic(String key, [dynamic defValue])
  {
    if (properties.containsKey(key))
    {
      return properties[key]?.value ?? defValue;
    }
    else
    {
      return defValue;
    }
  }

  /// Ziskani odkazu na objekt BindableProperty zadaneho nazvu.
  /// * Pokud objekt neexistuje vytvori ho, zaregistruje ho a priradi mu default value (vytvari creator)
  BindableProperty getOrCreateBindableProperty(String key, [PropertyBinderCreator? creator])
  {
    if (properties.containsKey(key))
    {
      return properties[key]!;
    }
    else
    {
      var result = BindableProperty(key, creator?.call(this));
      properties[key] = result;
      return result;
    }
  }

  /// Cte property jako objekt zadaneho typu.
  /// * Pokud nesoulasi property neexistuje, nebo nesouhlasi jeho typ vrati [defValue].
  T getProperty<T>(String name, T? defValue)
  {
    if (properties.containsKey(name))
    {
      final prop = properties[name];

      if (prop == null)
      {
        return defValue!;
      }
      else
      {
        return (prop.value is T) ? prop.value as T : defValue!;
      }
    }
    else
    {
      return defValue!;
    }
  }

  T _createProperty<T>(String key, PropertyBinderCreator creator)
  {
    final result = creator(this);
    properties[key] = BindableProperty(key, result);
    return result;
  }

  T getOrCreateProperty<T>(String name, PropertyBinderCreator creator)
  {
    if (properties.containsKey(name))
    {
      final prop = properties[name];

      if (prop == null)
      {
        return _createProperty(name, creator);
      }
      else
      {
        return (prop.value is T) ? prop.value as T : _createProperty(name, creator);
      }
    }
    else
    {
      return _createProperty(name, creator);
    }
  }

  static PropertyBinder of(BuildContext context)
  {
    final PropertyBinder? result = context.dependOnInheritedWidgetOfExactType<PropertyBinder>();
    assert(result != null, 'No PropertyBinder found in context');
    return result!;
  }

  static T ofT<T extends PropertyBinder>(BuildContext context)
  {
    final result = context.dependOnInheritedWidgetOfExactType<T>();
    assert(result != null, 'No PropertyBinder found in context');
    return result!;
  }

  static void doOn(BuildContext context, PropertyBinderDoOn caller)
  {
    final PropertyBinder? result = context.dependOnInheritedWidgetOfExactType<PropertyBinder>();
    if (result != null)
    {
      caller(result);
    }
  }

  static void doOnT<T extends PropertyBinder>(BuildContext context, PropertyBinderDoOn caller)
  {
    try
    {
      final T? result = context.dependOnInheritedWidgetOfExactType<T>();
      if (result != null)
      {
        caller(result);
      }
    }
    // ignore: empty_catches
    catch ($) {}
  }

  static void doOnProperty(BuildContext context, String key, PropertyBinderDoOnProperty caller)
  {
    final PropertyBinder? binder = context.dependOnInheritedWidgetOfExactType<PropertyBinder>();
    if (binder != null)
    {
      caller(binder, binder.getOrCreateBindableProperty(key, null));
    }
  }

  static void doOnPropertyT<T>(BuildContext context, String key, T defValue, PropertyBinderDoOnProperty caller)
  {
    final PropertyBinder? binder = context.dependOnInheritedWidgetOfExactType<PropertyBinder>();
    if (binder != null)
    {
      caller
      (
        binder,
        binder.getOrCreateBindableProperty
        (
          key, (binder)
          {
            return defValue;
          }
        )
      );
    }
  }

  @override
  bool updateShouldNotify(covariant PropertyBinder oldWidget)
  {
    return true;
  }
}

typedef PropertyBinderDoOn = void Function(PropertyBinder binder);
typedef PropertyBinderDoOnProperty = void Function(PropertyBinder binder, BindableProperty property);
typedef PropertyBinderCreator = dynamic Function(PropertyBinder binder);

class BindableProperty
{
  final events = <PropertyOnChange>[];
  final String key;
  late dynamic value;

  BindableProperty(this.key, this.value);

  bool compare(dynamic other)
  {
    bool result = false;

    try
    {
      final c1 = value as Comparable;

      result = c1.compareTo(other) == 0;
    }
    catch (_) {}

    return result;
  }

  T valueT<T>([T? defValue])
  {
    if (value is T)
    {
      return value as T;
    }
    else
    {
      return defValue!;
    }
  }

  void forceValue(PropertyBinder binder, dynamic newValue)
  {
    value = newValue;

    for (var element in events)
    {
      element(binder, this);
    }

    for (var element in binder.events)
    {
      element(binder, this);
    }
  }

  void setValue(PropertyBinder binder, dynamic newValue)
  {
    if (!compare(newValue))
    {
      forceValue(binder, newValue);
    }
  }
}

typedef PropertyOnChange = void Function(PropertyBinder binder, BindableProperty property);

/// Stav property binderu slouzi k pripojeni a odpojeni udalosti k jednotlivym property.
/// Stav je nutne uchovavat na urovni StatefulWidgetu a uvolnit vsechny navazane property ve behem [bind]
/// ```dart
/// class _MyHomePageState extends State<MyHomePage>
/// {
///   PropertyBinderState? binderState;
///
///   @override
///   Widget build(BuildContext buildContext)
///   {
///      . . .
///      bind(context);
///      . . .
///      // Zmena hodnoty property cnt
///      PropertyBinder.doOnProperty
///      (
///        context, 'cnt', (binder, property)
///        {
///            var cnt = property.valueT(0.0);
///            property.setValue(binder, cnt + 1);
///        }
///      );
///      . . .
///   }
///
///   // Pripojeni property cnt a vypsani jeji hodnoty po kazde zmene
///   void bind(BuildContext context)
///   {
///      binderState = PropertyBinderState.createOrChange(PropertyBinder.of(context), binderState);
///      binderState!.setOnChange
///      (
///        'cnt', (binder, property)
///        {
///          print('cnt = ${property.value as double}');
///        }
///      );
///   }
///
///  // Uvolneni binderState uvolni i onChange property 'cnt'
///  @override
///  void dispose()
///  {
///    super.dispose();
///    binderState?.dispose();
///    binderState = null;
///  }
///
/// }
/// ```
///
class PropertyBinderState
{
  final eventList = <_PropertyBinderStackItem>[];
  final PropertyBinder binder;

  /// Interni konstruktor
  PropertyBinderState._(this.binder);

  /// Vytvoreni / vymena objektu binder state
  /// * Typicky se pouziva v ramci build metody
  /// * Metode se predava puvodni objekt BinderState (nebo null pokud neexistuje)
  /// * Na puvodnim objektu se provede dispose
  /// * Vytvori se novy objekt BinderState a ten se vrati (pri dalsim volani bind se preda k dispose)
  static PropertyBinderState createOrChange(PropertyBinder binder, [PropertyBinderState? binderStack])
  {
    if (binderStack != null)
    {
      binderStack.dispose();
    }

    final newStack = PropertyBinderState._(binder);

    return newStack;
  }

  void setOnChange(String? name, PropertyOnChange onChange)
  {
    if (!eventList.any((e) => e.change == onChange))
    {
      eventList.add(_PropertyBinderStackItem(name, onChange));
      binder._setOnChange(name, onChange);
    }
  }

  void removeOnChange(PropertyOnChange onChange)
  {
    var list = eventList.where((e) => e.change == onChange);
    for (var event in list)
    {
      eventList.remove(event);
      binder._removeOnChange(event.name, event.change);
    }
  }

  void dispose()
  {
    for (var element in eventList)
    {
      binder._removeOnChange(element.name, element.change);
    }

    eventList.clear();
  }
}

class _PropertyBinderStackItem
{
  String? name;
  late PropertyOnChange change;

  _PropertyBinderStackItem(this.name, this.change);
}