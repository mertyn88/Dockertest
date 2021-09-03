## 쿠버네티스 설치
### 도커 설치 [(Homebrew로 Mac에 도커 설치하기)](https://dc7303.github.io/docker/2019/11/24/dockerInstallForMac/)

```bash
brew install --cask docker # 참고 사이트에서 알려주는 brew cask install docker 는 예전방식이라서 제대로 동작하지 않음
```

`brew cask(GUI용 brew)`로 설치해야 `Docker Desktop On Mac` 도커를 설치해주며, `docker-compose`, `docker-machine`을 같이 설치해준다. 쿠버네티스 설치시 해당 도커앱에 추가로 설치를 하는 것이므로 해당 방식으로 설치하자

우측 상단에 고래 모양 아이콘이 표시되면 정상 설치

### 쿠버네티스 추가 [(쿠버네티스 배포하기)](https://brunch.co.kr/@springboot/324)

정상적으로 `Docker Desktop On Mac`을 설치하였다면, 쿠버네티스는 설정에서 체크하는것만으로 설치를 할 수 있다.
**_도커 앱 -> 환경설정 -> 쿠버네티스 -> 쿠버네티스 활성화 체크_**를 하면 꽤 오래기다리면 성공적으로 동작함을 알 수있다.
![](https://images.velog.io/images/mertyn88/post/cd2a0fbc-9eb8-4ad5-88cc-ddb742828172/image.png)


### 쿠버네티스 정상 구동 확인하기
```bash
$kubectl cluster-info
Kubernetes master is running at https://kubernetes.docker.internal:6443
KubeDNS is running at https://kubernetes.docker.internal:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

### 쿠버네티스 정보 확인하기
```bash
$kubectl get all
```
  
## 쿠버네티스 Dashboard 구동하기
### Dashboard 설치
대시보드 설치는 미리 원격지에 정의되어 있는 kubernetes-dashboard.yaml 설정 파일을 통해 설치가 가능. 쿠버네티스 특정 이미지들을 올리는 작업이 있다.

```bash
$kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta1/aio/deploy/recommended.yaml
```

### Dashboard Proxy 실행 (기본 포트 8001)
```bash
$kubectl proxy  
```

### Dashboard Proxy 접근
> http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login

![](https://images.velog.io/images/mertyn88/post/2ee496d2-ecaf-425e-aefd-b3fb36f09eac/image.png)

### Dashboard Proxy Token 추출
여기서는 Token값을 추출하여 접속하는 방식으로 한다. 해당 명령어로 Token값을 추출하고, 복사하여 접속한다.

```bash
$kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```

**접속화면**
![](https://images.velog.io/images/mertyn88/post/00e3d324-ac59-4605-be11-245a937eda5e/image.png)

## 쿠버네티스 배포하기
### 샘플프로젝트 정보
[샘플프로젝트 Git](https://github.com/mertyn88/Dockertest)
* **Build tool** : gradle 5.6.4
* **Test url** : http://localhost:8080/api ( return "ok" )
* **Framework** : Spring Boot 2.1.6.RELEASE

### Dockerfile 작성
```go
FROM adoptopenjdk/openjdk11:alpine-jre
VOLUME /tmp
ARG JAR_FILE=build/libs/*.war
COPY ${JAR_FILE} app.war
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom","-jar","/app.war"]
```
> _**FROM adoptopenjdk/openjdk11:alpine-jre**_

OS의 용량문제때문에 최소한의 용량만을 가지고 있는 `alpine(알파인)`을 베이스 이미지로 지정했으며 `Java Version 11`로 버전이 명시되어 있다. 마지막으로 `jar`나 `war`형태로 배포를 할 것이므로 jdk가 아닌 `jre`로 명시하였다.

> _**ARG JAR_FILE=build/libs/*.war**_  
_**COPY ${JAR_FILE} app.war**_

${프로젝트위치}/build/libs의 모든 war파일을 대상으로 지정하였다.
war파일을 app.war로 복사하여 이름을 명확히 명시한다.

> _**ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom","-jar","/app.war"]**_

docker가 실행되고 나서 수행되어야 하는 명령을 작성한다. 여기서 java.security.egd에 대해서 -D옵션을 주었는데 몰라서 찾아보니 다음과 같다.  
[/dev/./urandom을 사용하는 이유](https://www.kangwoo.kr/2018/02/06/spring-boot-%EC%8B%9C%EC%9E%91%EC%8B%9C-dev-urandom%EC%9D%84-%EC%82%AC%EC%9A%A9%ED%95%98%EB%8A%94-%EC%9D%B4%EC%9C%A0/)
```text
스프링 부트를 이용해서 웹 애플리케이션을 만들 때, 기본적으로 톰캣을 이용하게 됩니다.
이 톰캣은 자바의 SecureRandom 클래스를 사용해서, 세션 아이디 같은 것을 생성하게 됩니다.
리눅스(linux) 환경의 경우, SecureRandom 클래스는 안전한 난수 생성을 위해서 /dev/random을 사용합니다.
/dev/random 경우 엔트로피 풀에 필요한 크기 만큼의 데이터가 부족할 경우, 블록킹(blocking) 상태로 대기하게 됩니다. 이런 경우 애플리케이션이 행(hang)에 걸린것 처럼 멈처버리는 현상이 발생합니다.
이 문제를 해결하기 위해서 /dev/urandom을 사용한 것입니다. 
왜 /dev/urandom이 아니라 /dev/./urandom을 사용했을까요? 그 이유는 자바 버그로 인해서 입니다.
Java5 이휴의 특정 버전에서는 /dev/urandom을 설정하면, /dev/random로 인식해 버리는 버그가 있습니다.
```

### 프로젝트 build

```bash
#war 파일 생성
$./gradlew clean build
```


### Docker build & check
```bash
#build
docker build -t [도커허브ID]/[프로젝트명] .
#check
docker images
```

### Docker login & push
```bash
#login
docker login
#push
docker [도커허브ID]/[프로젝트명]
```
![](https://images.velog.io/images/mertyn88/post/7d8ac1f2-6dc2-4cb6-b817-8e3f779dd207/image.png)

Dockerhub에 정상적으로 이미지가 push되었는지 확인
![](https://images.velog.io/images/mertyn88/post/912b5070-c881-4bb1-b9b9-5a4a7e113212/image.png)


### 쿠버네티스 배포파일(deployment.yaml 파일 생성)
다음 3가지 명령어로 deployment.yaml의 내용을 채운다  
[deployment.yaml](https://github.com/mertyn88/Dockertest/blob/master/deployment.yaml)
```bash
$kubectl create deployment [프로젝트명] --image=[도커허브ID]/[프로젝트명] --dry-run=client -o=yaml > deployment.yaml
$echo --- >> deployment.yaml
$kubectl create service clusterip [프로젝트명] --tcp=8080:8080 --dry-run=client -o=yaml >> deployment.yaml
```

### 쿠버네티스 배포 및 확인
```bash
#deploy
$kubectl apply -f deployment.yaml
#check
$kubectl get all | grep [프로젝트명]
```

### 쿠버네티스 Dashboard 로그 확인
화면에서 `Pods`부분의 오른쪽 영역메뉴 -> Logs를 통해 정상적으로 배포 및 war가 올라갔는지 확인 할 수 있다.
![](https://images.velog.io/images/mertyn88/post/94b0791e-3ad4-4a82-ab24-d3733c36156e/image.png)

### 외부 http 포트포워딩
```bash
$kubectl port-forward svc/example 8080:8080
#daemon print
Forwarding from 127.0.0.1:8080 -> 8080
Forwarding from [::1]:8080 -> 8080
#connect
Handling connection for 8080
Handling connection for 8080
```
![](https://images.velog.io/images/mertyn88/post/35e61dde-6df9-4146-8d23-e8916947c6b8/image.png)

## 마치며
실제 이방식이 실무방식은 아니라고 한다. 여러가지 규칙이 있고 자동화가 되어있을듯 하다. 처음들어보는 용어도 있고 도커가 무엇인지는 아는데 쿠버네티스를 한번도 경험해보지 않는 사람들에게 예시로 한번쯤 따라해볼만 한것 같다.
