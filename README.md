# 고객 만족도 향상 및 기업 이윤 증대를 위한 대시보드 개발

<br>

## 진행기간
> **2024/03/11~03/20**
<br>


## 사용 데이터
> **온라인 쇼핑몰 이커머스 데이터**
>
> https://www.kaggle.com/datasets/sharangkulkarni/oltp-ecommerce-data/data
<br>

<table width="100%">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/a6b8ea8c-9272-40db-91f3-fdc7c60b563d" width="90%">
    </td>
  </tr>
</table>
<br>


## 개발 환경
> **MySQL, Tableau, Python**
<br>

### 역할
> **EDA,  Data Preprocessing, 코드 통합, 시각화, 상품 추천 대시보드 제작(평점, 리뷰, 재구매,..), 환불 분석 대시보드 제작**
<br>

## 분석 주제
> **고객 만족도 향상 및 기업 이윤 증대를 위한 대시보드 제작**
<br>


## 분석 요약(담당 부분)

1. Data Preprocessing(Python)
2. EDA(MySQL)
    1. 평점, 리뷰
    2. 재구매 분석
    3. 환불 분석
3. 대시보드 제작(Tableau)
    1. 평점, 리뷰, 재구매율을 활용한 상품 추천
    2. 환불 분석
<br>

- **전체 대시보드**
    - **고객용 대시보드**
        - 평점, 리뷰, 재구매율을 활용한 상품 추천
        - 카테고리 별 인기상품 추천
    - **기업용 대시보드**
        - 매출 실적 현황 파악
        - 캠페인 효과 분석
        - 환불 분석


## 분석 과정

### *Data Preprocessing*
<br>

- orders 셋에 campaign_id 가 Null 인 경우가 있는데 여기서 문제가 발생
    - INT 형에 공백이 들어갈 경우 import 오류 발생(MySQL)

- Null 값이 진짜 결측인게 아니라 캠페인을 진행하지 않은 기간이므로 NoCapaign 행을 추가 삽입(marketing_campaigns)
- 맨 마지막으로 삽입하여 campaign_id 는 17로 지정(AUTO_INCREMENT 조건으로 0값으로 넣지 못함 )
- orders에서 campaign_id 가 결측인 것은 17로 바꿔주고 int형으로 바꾸어준 후 저장
- campaign_product_subcategory 에서도 subcategroy_id 별 campaign_id 가 17인 경우 discount 값은 0 값으로 총 100개 행 추가 삽입

<br>

### *EDA(MySQL): 상품 추천 대시보드*

**`평점 평균, 리뷰수, 긍정리뷰비율`**

- `상품별`


<table width="100%">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/ef29978b-8a31-4540-b8cc-5e6c311bdd45" width="90%">
    </td>
  </tr>
</table>

- 평점, 리뷰수, good 비율을 활용하여 우수 상품 추천 가능
- 이 후 재구매율을 분석할 때 이를 활용하여 순위 지정 후 상품 추천 진행함

<br>

- `카테고리별`


<table width="100%">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/cf0a1fdd-7585-4ab6-9e64-4d7f03fd0251" width="90%">
    </td>
  </tr>
</table>

- 리뷰 수의 경우 특정 카테고리에 쏠린다면 긍정리뷰의 비율의 의미가 퇴색될 수 있으나 그러한 경우는 없었음

<br>

- `국가별`


<table width="100%">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/ed30783c-e850-4f9a-970d-ea03e48a7086" width="90%">
    </td>
  </tr>
</table>
<br>

- `소비자`

<table width="100%">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/67708ee2-da9a-4890-8319-998600b93893" width="90%">
    </td>
  </tr>
</table>

<table width="100%">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/1af31817-86ce-4356-8167-84bfe33a65c1" width="90%">
    </td>
  </tr>
</table>

- 인당 평균적으로 10개의 리뷰를 작성
- 모든 고객이 평점을 매기거나 리뷰를 남기므로 적극성을 파악할 수 있음

<br>

**`재구매 분석`**

`소비자별 특정 상품 구매 총 횟수, 재구매횟수, 재구매까지 걸린 시간, 모든 상품 총 구매 횟수`

<table width="100%">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/df69da89-ce6b-49a1-8ef8-e62f07295914" width="90%">
    </td>
  </tr>
</table>
<br>


### *대시보드 생성 위한 EDA 및 테이블 생성: 상품 추천 대시보드*

- **고객에게 어떤 상품을 어떤 근거로 추천할 것인가?**
    1. 몇 개의 카테고리를 추천하면 좋을까?
        
        ⇒ 소비자가 구매건수마다 평균적으로 몇 가지의 카테고리를 구매하는지 확인
        
    2. 카테고리 내의 서브 카테고리를 재선택 할 수 있도록 구성, 이 때 우수한 서브 카테고리 일 수록 크기가 더 크게!
        
        ⇒ 커서를 올릴 시 서브 카테고리 별로 평균 낸 평점, 재구매율 등 전체적인 정보 볼 수 있도록 구성해보자
        
    3. 서브 카테고리를 재선택 후 상세한 상품 정보를 확인할 수 있도록 구성해보자

- `소비자 별로 구매건수마다 평균 몇 가지의 카테고리를 구입하는지 확인`


<table width="100%">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/afc91992-2dea-4e3c-9224-114241be79d7" width="90%">
    </td>
  </tr>
</table>

- 보통 4~5가지의 카테고리에 해당하는 상품을 구입. 전체 평균은 4.75임을 확인

<br>

- `소비자별 가장 많이 구입하는 상위 5개의 카테고리 데이터 셋 생성`
    - 구입 횟수가 같은 경우 재구매율, 평균 평점을 기준으로 우선 순위 생성


<table width="100%">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/9a519ec9-e340-4c53-bf1b-4a84d12cd19f" width="90%">
    </td>
  </tr>
</table>
<br>

- `카테고리 내 재구매율, 평균 평점, 긍정 리뷰 비율, 구매 횟수 등`

<table width="100%">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/bbbd63aa-99fb-4140-ad68-54e0aca2169f" width="90%">
    </td>
  </tr>
</table>
<br>

- `서브카테고리 내 품목 정보 제공(평점, 리뷰수, 감성분석: 긍정리뷰비율, 재구매율)`


<table width="100%">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/47e020ad-0277-401d-999f-46d4e01476e7" width="90%">
    </td>
  </tr>
</table>
<br>

**`최종 상품 추천 대시보드`**

https://public.tableau.com/views/_17105847660520/1?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link
<br>

<table width="100%">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/801c6116-ab0a-4cb7-96fb-13d209ca800c" width="90%">
    </td>
  </tr>
</table>

- **최상단 : 고객별 상품 추천 위해 특정 고객 선택 가능**
- **좌측상단 : 해당 고객이 가장 많이 구입한 카테고리 상위 5개 제공. 구매횟수별로 크기 적용**
- **우측상단 : 좌측상단의 카테고리 선택 시 우수한 서브카테고리 순서로 크기와 음영 적용(우수함은 재구매율, 평점, 긍정리뷰비율 순위 총합 낮은 순)**
- **하단 : 우측 상단의 서브카테고리 선택 시 해당 상품의 평점, 리뷰수, 긍정리뷰비율, 재구매율 정보 제공**
<br>

### *EDA & 대시보드 생성 위한 테이블 생성: 환불 분석 대시보드*

- **모든 상품에서 환불이유를 찾고 해결하는 것은 중요하나, 특히 빠르게 대처해야하는 상품은 무엇일지, 정말 문제가 있는 상품이 있는 건지 등을 나타낼 수 있는 타겟을 설정한 분석 진행을 목표**

- `환불 이유별 횟수`


<table width="100%">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/65dd2d26-a9f1-4651-ade1-ee90dda34398" width="90%">
    </td>
  </tr>
</table>

- 환불 이유가 총 10개 밖에 없음
- 환불 이유를 텍스트로 적는게 아니라 선택형
    - 굳이 텍스트 분석을 진행할 필요가 없음. 특정 단어를 뽑아서 분석할 필요도 없음

<br>

- `지역별 환불 분석`


<table width="100%">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/cde16829-9683-403f-a6fb-d628d54dab2f" width="90%">
    </td>
  </tr>
</table>

- 204개국에 물건을 파는 데이터로써 나라마다 물류 구조가 불량할 수도 있고 배송 오류가 많을 가능성이 높을 것으로 예상
- 환불이유별 횟수를 보면 배송 오류에 관련한건 낮은데 만일 환불이 많은 나라별 **상위 환불 이유가 배송 오류라면 가설**이 맞는 것
    - **확인 결과 가설이 맞아떨어짐**
    - 시각적으로 볼 시 더 확연하게 드러남
    - 해당 나라의 담당 물류업자 혹은 물류 구조를 파악할 필요성을 제공

<br>


- `환불율 분석`

<table width="100%">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/5b50a80a-4adc-4bec-a72e-cf5065678311" width="90%">
    </td>
  </tr>
</table>

- 나라를 특정하여 분석했을 때는 ‘환불횟수’ 가 의미가 있었지만 이는 상품 자체의 오류를 찾기는 어려움
- 특정 상품의 문제를 찾기위해서는 subcategory 내에서 특정 상품이 환불율이 높은 것을 찾아야 함
- subcategory 내에서 평균 보다 일정 표준편차보다 높은 환불율 값을 가지는 상품 탐색
    - 총 10개의 상품 선정할 수 있었음
    - 상품별 상위 환불이유를 찾고 위의 이상 상품과 연결지어 분석 후 제품 이상에 대해 파악가능

<br>

- `상품별 상위 환불 이유`

<table width="100%">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/7f19ed71-e3d0-4518-a09c-84adc9b60477" width="90%">
    </td>
  </tr>
</table>
<br>

**`최종 환불 분석 대시보드`**

https://public.tableau.com/views/_17107162662210/1?:language=ko-KR&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link

<br>

<table width="100%">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/8dfe67e0-e4bb-423d-8af7-4169d184c309" width="90%">
    </td>
  </tr>
</table>

> **좌측상단 : 환불 이유 별 총 횟수를 나타내는 트리맵으로 환불 횟수가 많았던 이유일수록 더 진함**
> 

> **좌측하단 : 환불 횟수가 가장 많은 상위 5개 국가의 환불 이유를 중심으로 막대그래프 생성**
> 
> 
> > **좌측 상단의 그래프를 보았을 때 배송 오류와 관련된 환불 이유의 횟수는 적었지만 가장 환불이 많은 나라에서는 그와 반대로 배송오류가 압도적으로 많음**
> > 
> 
> > **해당 나라의 물류 구조 혹은 담당 배송 업자 파악 필요성 인사이트 제시 가능**
> > 

> **우측상단 : subcategory 내에서 평균 보다 일정 표준편차보다 높은 환불율 값을 가지는 상품 탐색. 각 막대별 중간에 있는 하늘색 라인은 각 상품에 해당하는 서브카테고리의 환불율 평균을 나타냄**
> 

> **우측하단 : 우측상단의 특정 상품을 선택했을 시 해당 상품의 환불이유와 각 횟수 정보 제공**
> 

<br>


**`캠페인 주자별 구매수량 및 매출 대시보드`**


<table width="100%">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/fe51b503-fea1-441a-8df5-3ef0cca8e36e" width="90%">
    </td>
  </tr>
</table>
<br>


## 시사점 및 보완할 점

- **상품 추천 대시보드**
    - 평점, 리뷰, 긍정 리뷰 비율: 상품별, 카테고리별 데이터를 통해 인기 상품 및 고객 만족도를 측정
    - 재구매율 분석: 우수 상품과 높은 재구매율을 가진 카테고리 중심으로 추천
    - 국가별/소비자별 분석: 특정 국가와 고객 그룹의 구매 성향을 분석해 맞춤 전략 제안
    - `고객용 대시보드: 맞춤형 상품 추천, 구매 이력 기반 시각화`
        - 일반 사용자들이 쉽게 접근하여 활용할 수 있는 형태로 구성
        - 사용자들이 제품 또는 서비스와 관련된 데이터를 쉽게 시각화하고 해석 가능
        - 고객의 과거 구매 이력과 선호도를 기반으로 한 맞춤형 상품 추천 가능
- **환불 분석 대시보드**
    - 환불 이유 분석: 환불의 주요 원인(예: 품질 문제, 배송 오류) 파악
    - 지역별 환불 분석: 특정 국가에서 물류 문제로 인한 환불률 증가 식별
    - 환불률 분석: 환불률이 높은 상품과 카테고리 분석으로 품질 관리 개선 제안
    - `기업용 대시보드: 판매량, 매출, 환불 데이터를 기반으로 전략적 의사결정 지원`
        - 기업의 전반적인 건강 상태 및 성과를 파악하고, 전략을 개선하는 데 필요한 인사이트를 제공
- **캠페인 효과 분석**
    - 캠페인은 매출 증가보다 판매량 증가에 더 효과적이며, 할인율이 높은 고가 상품에서 효과적임
    - 세부분석이 필요하지만 진행하지 못함
    - 저소득 국가에서의 높은 결제액은 새로운 마케팅 기회로 평가
        - 더 좋은 시각화 방법 찾거나, 이 시각화 속에서라도 도출할 수 있는 인사이트 제시 필요
        - ex. 8월의 BackToSchoolSale의 경우 2016년에는 저조했지만 2017년에는 매우 많은 구매수량, 즉 구매건수가 늘어났다
- **종합**
    - `MySQL`을 이용해 DDL 구조를 작성 후 데이터 처리
    - `EDA`는 `MySQL`을 활용하여 진행, `대시보드 제작`은 `Tableau` 활용
    - Slack, Gather Town, Notion 이용하여 정보 공유 및 진행 내용 정리
    - 단순히 데이터를 나열하는 대시보드를 제작하는 것이 아닌 아래의 질문을 중점으로 세부 주제 선정
        - 고객은 어떤 대시보드를 보고 상품을 구매할 마음이 들 것인가?
        - 기업은 어떤 대시보드를 보고 매출을 늘리기 위한 계획을 세울 수 있을 것인가?
        - 한 눈에 필요한 정보를 얻을 수 있는가?
    - 고객 만족도 향상
        - 인기 상품 파악 및 평점 등의 정보 제공으로 고객들의 선호도를 이해하고 그에 맞는 상품 제공 가능
    - 마케팅 전략 수립
        - 재구매율 및 국가별, 카테고리별 인기 상품을 분석해 타겟 고객층을 파악 후 효율적인 마케팅 전략  수립 가능
    - 정보제공 및 의사결정
        - 캠페인에 따른 판매량 및 매출액, 결제 트랜드, 연도/분기/월별 매출 등 필요한 정보를 제공하고 의사 결정을 도움
    - 환불 관리 및 예방
        - 높은 환불 값을 가지는 이유와 상품 카테고리를 파악하고, 상품에 따른 환불 이유를 분석해 환불 예방 가능








