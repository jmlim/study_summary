
 > 자료 출처
>  - 헤드퍼스트 디자인 패턴
 
## 팩토리
 - 팩토리를 이용하여 불필요한 의존성을 없애는 방법을 알아보기.

- 구상 클래스를 바탕으로 코딩을 하면 나중에 코드를 수정해야 할 가능성이 높아지고 유연성이 떨어짐.
- 일련의 구상 클래스들이 있을 때는 어쩔 수 없이 다음과 같은 코드를 만들어야 하는 경우가 생김.
- 구상클래스 용어에 대한 어색함
    - https://javacan.tistory.com/entry/%EA%B5%AC%EC%83%81-%ED%81%B4%EB%9E%98%EC%8A%A4%EB%9E%80-%EC%9A%A9%EC%96%B4%EC%9D%98-%EC%96%B4%EC%83%89%ED%95%A8


~~~java
Duck duck; 

if(picnic) {
    duck = new MallardDuck();
} else if(hunting) {
    duck = new DecoyDuck();
} else if(inBathTub) {
    duck = new RubberDuck();
}

/**
    오리를 나타내는 클래스들이 여러가지 있지만, 컴파일시에는 어떤 것의 인스턴스를 만들어야 할 지 알 수 없음.
*/
~~~ 

- 이런 코드가 있다는 것은, 뭔가 변경하거나 확장해야 할 때 코드를 다시 확인하고 추가 또는 제거해야 한다는 것을 뜻함.
    - 코드를 이런식으로 만들면 관리 및 갱신하기가 어려워지고, 오류가 생길 가능성도 높아짐.
- "new" 에 문제가 있는 것인가?
    - new 자체에 문제가 있는 것은 아님.
    - 자바에서 가장 근본적인 뼈대를 이루고 있는 것이기 때문에 전혀 쓰지 않을 수는 없음.
    - 진짜 말썽을 일으키는 놈은 "변화" 임.
- 인터페이스에 맞춰서 코딩을 하면 시스템에서 일어날 수 있는 여러 변화를 이겨낼 수 있음.
    - 다형성 덕분에 어떤 클래스든 특정 인터페이스만 구현하면 사용할 수 있기 때문임.
    - 다형성에 대한 내용은 아래 문서 참고
        - https://wikidocs.net/269
    - 반대로 코드에서 구상 클래스를 많이 사용하면 새로운 구상 클래스가 추가될 때마다 코드를 고쳐야 하기 때문에 수 많은 문제가 생길 수 있음.
        - 즉, 변화에 대해 닫혀 있는 코드가 됨.
        - 새로운 구상 형식을 써서 확장해야 할 때 어떻게 해서든 다시 열 수 있어야 한다.
            - OCP : 변경에 대해서는 닫혀 있어야 하나 확장에 대해서는 열려 있어야 함.

> 바뀔 수 있는 부분을 찾아내서 바뀌지 않는 부분하고 분리시켜야 한다.

### 피자 오더 예제
~~~java
    ...
    Pizza orderPizza(String type) {
        Pizza pizza;
        if(type.equals("cheese")) {
            pizza = new CheesePizza();
        } else if(type.equals("pepperoni")) {
            pizza = new PepperoniPizza();
        } else if(type.equals("clam")) {
            pizza = new ClamPizza();
        } else if(type.equals("veggie")) {
            pizza = new EggiePizza();
        }

        pizza.prepare();
        pizza.bake();
        pizza.cut();
        pizza.box();
        return pizza;
    } 

    /**
        - 일단 이 코드는 코드 변경에 대해 닫혀있지 않음.
        - 위 조건문에 대해선 피자 종류가 바뀔때마다 코드를 고쳐야 한다.
    */
    ...
~~~

### 객체 생성 부분 캡슐화
 - 객체 생성 코드만 따로 빼서 피자 객체를 만드는 일만 전담하는 다른 객체에 집어넣음.
 - 새로 만들 객체에는 팩토리(Factory) 라는 이름을 붙이기로 함.

~~~java
public class SimplePizzaFactory {
    public Pizza createPizza(String type) {
        Pizza pizza = null;

        if(type.equals("cheese")) {
            pizza = new CheesePizza();
        } else if(type.equals("pepperoni")) {
            pizza = new PepperoniPizza();
        } else if(type.equals("clam")) {
            pizza = new ClamPizza();
        } else if(type.equals("veggie")) {
            pizza = new EggiePizza();
        }

        return pizza;
    }
}
~~~
Q. 이렇게 하면 무슨 장점이 있는 건가?
    - 피자를 생성하는 작업을 한 클래스에 캡슐화 시켜 놓으면 구현을 변경해야 하는 경우에 여기저기 다 들어가서 고칠 필요없이 이 팩토리 클래스 하나만 고치면 됨.
Q. 비슷한 식으로 팩토리를 쓰는데 메소드를 정적 메소드로 선언한 디자인을 본적이 있음. 그거랑 이거랑 어떻게 다른거죠?
    - 간단한 팩토리를 정적 메소드(static method) 로 정의하는 기법도 일반적으로 많이 쓰임. 
    - 정적 메소드를 쓰면 객체를 생성하기 위한 메소드를 실행히기키 위해 객체의 인스턴스를 만들지 않아도됨.
        - 하지만 서브클래스를 만들어서 객체 생성 메소드의 행동을 변경시킬 수 없다는 단점도 존재함.

### PizzaStore 클래스 수정
 - 팩토리를 이용해서 피자 객체를 생성하도록 함.

~~~java
    public class PizzaStore {
        SimplePizzaFactory Factory;

        public PizzaStore(SimplePizzaFactory Factory) {
            this.Factory = factory;
        }

        public Pizza orderPizza(String type) {
            Pizza pizza;

            // new 연산자 대신 팩토리 객체에 있는 create 메소드를 사용.
            pizza = factory.createPizza(type);

            pizza.prepare();
            pizza.bake();
            pizza.cut();
            pizza.box();
            return pizza;
        }
    }
~~~

- 간단한 팩토리는 디자인 패턴이라고는 할 수 없음.
    - 프로그래밍을 하는데 있어서 자주 쓰이는 관용구에 가깝다고 할 수 있음.
- 하지만 팩토리가 진짜 패턴이 아니라고 해서 확실하게 짚고 넘어가지 않아도 되는 건 아님.
    - 클래스 다이어그램 한번 살펴보고 가자.


<img src="/design_pattern/factory_img/factory_img.jpg" />


 > 간단한 팩토리는 워밍업이라고 생각하고, 팩토리에 해당하는 아래 두 가지 강력한 패턴에 대해 알아보자.


-----------------

## 팩토리 메소드 패턴

 - 모든 팩토리 패턴에서는 객체 생성을 캡슐화함.
 - 팩토리 메소드 패턴에서는 서브클래스에서 어떤 클래스를 만들지를 결정하게 함으로써 객체 생성을 캡슐화.
 - 간단한 팩토리하고 비슷하긴 하지만 방법이 조금 다름.
    - 구상 클래스를 만들 때 createPizza() 추상 메소드가 정의되어 있는 추상 클래스를 확장해서 만듬.
    - createPizza() 메소드에서 어떤 일을 할 지는 각 분점에서 결정함.

### 예제 
### Pizza.java (Product)
~~~java
public abstract class Pizza {
	String name;
	String dough;
	String sauce;
	List<String> toppings = new ArrayList<String>();
 
	void prepare() {
		System.out.println("Prepare " + name);
		System.out.println("Tossing dough...");
		System.out.println("Adding sauce...");
		System.out.println("Adding toppings: ");
		for (String topping : toppings) {
			System.out.println("   " + topping);
		}
	}
  
	void bake() {
		System.out.println("Bake for 25 minutes at 350");
	}
 
	void cut() {
		System.out.println("Cut the pizza into diagonal slices");
	}
  
	void box() {
		System.out.println("Place pizza in official PizzaStore box");
	}
 
	public String getName() {
		return name;
	}

	public String toString() {
		StringBuffer display = new StringBuffer();
		display.append("---- " + name + " ----\n");
		display.append(dough + "\n");
		display.append(sauce + "\n");
		for (String topping : toppings) {
			display.append(topping + "\n");
		}
		return display.toString();
	}
}
~~~

### PizzaStore.java (Creator)
~~~java
public abstract class PizzaStore {
 
	abstract Pizza createPizza(String item);
 
	public Pizza orderPizza(String type) {
		Pizza pizza = createPizza(type);
		System.out.println("--- Making a " + pizza.getName() + " ---");
		pizza.prepare();
		pizza.bake();
		pizza.cut();
		pizza.box();
		return pizza;
	}
}
~~~

### NYPizzaStore.java (Creator 구상 클래스)
~~~java
public class NYPizzaStore extends PizzaStore {

	Pizza createPizza(String item) {
		if (item.equals("cheese")) {
			return new NYStyleCheesePizza();
		} else if (item.equals("veggie")) {
			return new NYStyleVeggiePizza();
		} else if (item.equals("clam")) {
			return new NYStyleClamPizza();
		} else if (item.equals("pepperoni")) {
			return new NYStylePepperoniPizza();
		} else return null;
	}
}
~~~

### NYStyleCheesePizza.java  (Product 구상 클래스)
~~~java
public class NYStyleCheesePizza extends Pizza {

	public NYStyleCheesePizza() { 
		name = "NY Style Sauce and Cheese Pizza";
		dough = "Thin Crust Dough";
		sauce = "Marinara Sauce";
 
		toppings.add("Grated Reggiano Cheese");
	}
}
~~~

<img src="/design_pattern/factory_img/factory_method_img.jpg" />

-------
## 추상 팩토리 패턴
 - 인터페이스를 이용하여 서로 연관된, 또는 의존하는 객체를 구상 클래스를 지정하지 않고도 생성 가능.
 - 목적
    - 구체적인 클래스를 알지 못하고, 서로 관련성이 있으나, 독립적인 여러객체 군을 생성하기 위한 인터페이스를 제공하기 위해 사용.
 - 활용
    - 관련된 객체군을 함께 사용해서 시스템을 설계할 때.

 - 피자를 찍어낼 시 피자에 들어가는 재료의 종류인 도우, 치즈등을 넣을 때 추상 팩토리 패턴을 사용할 수 있음.
    - 추상 팩토리라고 부르는 새로운 형식의 팩토리를 도입해서 서로 다른 피자에서 필요로 하는 원재료군을 생산하기 위한 방법을 구축할 수 있다.
    - 제품군을 생성하기 위한 인터페이스를 제공.
        - 반죽, 소스, 치즈, 고기, 야채
    - 코드가 실제 제품하고 분리되어 있으므로 다른 공장을 사용하기만 하면 다른 결과를 얻을 수 있음.

### 원재료 공장 만들기
 - 원재료를 생산할 팩토리를 위한 인터페이스를 정의

~~~java
public interface PizzaIngredientFactory {
	Dough createDough();
	Sauce createSauce();
	Cheese createCheese();
	Veggies[] createVeggies();
	Pepperoni createPepperoni();
	Clams createClam();
}
// 재료마다 하나씩 클래스를 만들어야 함.
~~~

### 뉴욕 원재료 공장
 - 이 팩토리에서는 마리나라 소스, 레지아노 치즈, 신선한 조개 등을 전문적으로 생산.

~~~java
public class NYPizzaIngredientFactory implements PizzaIngredientFactory {
 
	public Dough createDough() {
		return new ThinCrustDough();
	}
 
	public Sauce createSauce() {
		return new MarinaraSauce();
	}
 
	public Cheese createCheese() {
		return new ReggianoCheese();
	}
 
	public Veggies[] createVeggies() {
		Veggies veggies[] = { new Garlic(), new Onion(), new Mushroom(), new RedPepper() };
		return veggies;
	}
 
	public Pepperoni createPepperoni() {
		return new SlicedPepperoni();
	}

	public Clams createClam() {
		return new FreshClams();
	}
}
~~~

### 피자 클래스 변경.
 - Pizza  클래스에서 팩토리에서 생산한 원재료만 사용하도록 코드를 고쳐야 함.
~~~java
public abstract class Pizza {
	String name;

	Dough dough;
	Sauce sauce;
	Veggies veggies[];
	Cheese cheese;
	Pepperoni pepperoni;
	Clams clam;

	abstract void prepare(); // 추상메소드로 만듬

	void bake() {
		System.out.println("Bake for 25 minutes at 350");
	}

	void cut() {
		System.out.println("Cutting the pizza into diagonal slices");
	}

	void box() {
		System.out.println("Place pizza in official PizzaStore box");
	}

	void setName(String name) {
		this.name = name;
	}

	String getName() {
		return name;
	}

	public String toString() {
		// 피자 이름을 출력하는 부분
	}
}
~~~

### 피자 클래스 변경. (구상클래스, 치즈피자)
~~~
public class CheesePizza extends Pizza {
	PizzaIngredientFactory ingredientFactory;
 
    // 원재료를 제공하는 공장이 필요 
    // 각 피자 클래스에서는 생성자를 통해서 팩토리를 전달 받음.
	public CheesePizza(PizzaIngredientFactory ingredientFactory) {
		this.ingredientFactory = ingredientFactory;
	}
 
	void prepare() {
		System.out.println("Preparing " + name);
		dough = ingredientFactory.createDough();
		sauce = ingredientFactory.createSauce();
		cheese = ingredientFactory.createCheese();
	}
}
~~~

### 피자 가게 클래스 (구상클래스, 뉴욕피자 스토어)
~~~java
public class NYPizzaStore extends PizzaStore {
	protected Pizza createPizza(String item) {
		Pizza pizza = null;
		PizzaIngredientFactory ingredientFactory = 
			new NYPizzaIngredientFactory();
		if (item.equals("cheese")) {
  
			pizza = new CheesePizza(ingredientFactory);
			pizza.setName("New York Style Cheese Pizza");
  
		} else if (item.equals("veggie")) {
 
			pizza = new VeggiePizza(ingredientFactory);
			pizza.setName("New York Style Veggie Pizza");
 
		} else if (item.equals("clam")) {
 
			pizza = new ClamPizza(ingredientFactory);
			pizza.setName("New York Style Clam Pizza");
 
		} else if (item.equals("pepperoni")) {

			pizza = new PepperoniPizza(ingredientFactory);
			pizza.setName("New York Style Pepperoni Pizza");
 
		} 
		return pizza;
	}
}
~~~

<img src="/design_pattern/factory_img/abstract_factory_img.jpg" />

- 객체가 객체를 생성함. 
    - 다양한 구성 요소 별로 "객체의 집합"을 생성해야 할 때 유용.
- 팩토리 메소드 패턴은 클래스를 이용하여 객체를 만들고, 추상 팩토리 패턴은 객체 구성을 통해 객체를 만든다.
