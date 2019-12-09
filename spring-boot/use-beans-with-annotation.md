### Spring의 getBeansWithAnnotation 을 이용하여 annotation을 선언한 빈 정보 읽기

- getBeansWithAnnotation 메소드를 활용하면 스프링에서 제공하는 annotation 뿐만 아니라, 내가 만든 annotation 을 선언한 빈들도 찾을수 있다.
    - 여러 곳에서 활용 가능. 
    - ex) 특정 annotation 을 선언한 놈을 찾아서 그놈들에 대한 단위 테스트를 구현한다던지, 해당 클래스를 observer 패턴등을 이용해서 일괄적으로 어떤 행위를 시킬수 있을 것임.

~~~
@RunWith(SpringRunner.class)
@SpringBootTest
public class DfApplicationTests {

    @Test
    public void testName1() throws Exception {

        System.out.println("========== @Service List ==========");
        Map<String, Object> serviceBeans = context.getBeansWithAnnotation(Service.class);
        for (Map.Entry<String, Object> entryBean : serviceBeans.entrySet()) {
            String beanName = entryBean.getKey();
            Object beanObject = entryBean.getValue();

            System.out.println("Class : " + beanObject.getClass().getCanonicalName());
            System.out.println("Bean Name : " + beanName);
        }

        System.out.println("========== @Repository List ==========");
        Map<String, Object> reposBeans = context.getBeansWithAnnotation(Repository.class);
        for (Map.Entry<String, Object> entryBean : reposBeans.entrySet()) {
            String beanName = entryBean.getKey();
            Object beanObject = entryBean.getValue();

            System.out.println("Class : " + beanObject.getClass().getCanonicalName());
            System.out.println("Bean Name : " + beanName);
        }
    }
}
~~~

출처
 - http://www.mungchung.com/xe/spring/103299
 - http://blog.naver.com/PostView.nhn?blogId=bestdriver94&logNo=206462800&parentCategoryNo=&categoryNo=&viewDate=&isShowPopularPosts=false&from=postView
