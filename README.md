Why we chose this topic:
With the pandemic now over, vast amounts of data are available on the case rates per country, patients registered in hospitals,
and spread of COVID-19 variants, and vaccine use by country. In order for health organizations such as the WHO to get a better sense
of how countries responded to the pandemic, a database is needed to compile country data, variant data, and vaccine data to cross tabulate
results on intersections of these data. This intersection is represented by examples such as vaccinations per country by day and
distribution of variants across different countries.
We also wanted to connect patient data to the database so that local hospitals can upload their own registry of patients and look
up how their patients related to global vaccinations. But due to HIPAA policies, real patient information at the specific level
was not recorded in country-wide vaccination records.

Patient lookup information was limited to age, gender, race, and boolean symptom details. So, for the purposes of this database, we created an ideal mock patient dataset that tracked patient cases by these details AND variant they were infected with, so they could be associated with lookups by variant. Unfortunately, for a comprehensive database to work at the patient level, vaccination records would have needed to be recorded by patient, which they were not. So our database DOES work at the case level, to evaluate an individual’s risk based on the metrics available in the PATIENTCASE2 entity, but not in other entities. I.e., the patient entity does not have much use when joined to the other main entities, but has function on its own.

Our idea is that at the hospital level, users can determine risk level of a specific patient due to age, gender, or comorbidity, and other available metrics
in the sample of PatientCase2. Assuming the sample in the mock dataset is a good estimate of the global population, risk calculations at the hospital level
can help inform healthcare professionals about susceptibility.
At the organizational level (like the WHO), a user can use the database across Country, Vaccine, and Variant to determine the distribution of vaccines
relative to risk level related to unvaccinated percentage, mortality rate, and other extractable metrics.

Target outputs from database application: 
We plan to market our database to the WHO, an organization formed by the UN in 1948 to promote the wellbeing of people
around the world. The WHO has an ongoing initiative to provide universal health coverage globally. In times of emergency,
like the pandemic, the WHO was essential in distributing medical resources to those in need.

There is no doubt that some demographics are more susceptible to COVID-19 than others. This is true for the pathology of all diseases, not just
COVID-19. The reasons that some demographics are at higher risk comes down to anthropological, cultural, and political
factors of the place they live – essentially, it is a community problem, not a biological one. According to the Mayo clinic,
significant differences in positive case rates between groups could be attributed to factors like comorbidities
(having concurrent diseases worsens prognosis), lack of access to healthcare, national/local poverty or upheaval, treatment
stigmas relating to religion or politics, and type of work the person does (in person workers were more susceptible), just to name a few. 

With the pandemic now over, vast amounts of data are available on the case rates per country and the performance of the world overall.
It is true that each country in the world is at a different place in their development index. And there is more than one reason why
that is the case. So it is unrealistic for us to paint a perfect picture of the factors that affect each country in the world. What
we can do is determine where significant differences exist between demographics in recovery from COVID-19. These significant
differences are indicators of social, cultural, or medical barriers that these demographics face in healthcare, which may still exist
post-pandemic. 

Our database will compare patient data from various locations around the world and determine which ethnicities,
genders, and age groups were most affected in each country for which data is available. In this article by the NIH, it is
mentioned that new data science methods are breaking the ice in treating COVID-19, and tools like it are needed in the future.
Problems of most relevance are finding successful contact tracing methods, analyzing global response to COVID-19, assessing economic
impacts, mining patient data, mining scientific literature, and mining social media responses. We aim to address the subject
of analyzing global response by mining patient data. Our database will deliver statistics on patient health, but not the anthropological
context of those statistics, which would require further research outside the scope of our database. 

Main entities:
1) Country: countryID (primary key INT)
2) Vaccine: VaccineID (primary key INT)
3) Variant: VariantID (primary key INT)
4) PatientCase: CaseID (primary key INT)
5) PatientCase2: CaseID (primary key INT)
6) Country-Vaccine (VaccinationRecord): associative: VaccinationRecordID (primary key INT), CountryID (FK1), VaccineID (FK2)
7) Country-Variant: associative: CountryVariantID (primary key INT), CountryID (FK1), VariantID (FK2)

Business Needs: 
Demographic Susceptibility: 
https://www.mayoclinic.org/diseases-conditions/coronavirus/expert-answers/coronavirus-infectio 
n-by-race/faq-20488802 

NIH Business Needs: 
https://pmc.ncbi.nlm.nih.gov/articles/PMC8607150/#s4 

About the WHO: 
https://www.who.int/about 

Datasets: 
Global Case count: 
https://www.kaggle.com/datasets/imdevskp/corona-virus-report?select=full_grouped.csv 

Variants of COVID-19: 
https://www.kaggle.com/datasets/lumierebatalong/covid-19-variants-survival-data 

Vaccinations by manufacturer: 
https://www.kaggle.com/datasets/gpreda/covid-world-vaccination-progress?select=country_vacc 
inations by manufacturer.csv 

Vaccinations by country:
https://www.kaggle.com/datasets/gpreda/covid-world-vaccination-progress?select=country_vacc 
inations.csv 

Patients with comorbidities global:
https://www.kaggle.com/datasets/shirmani/characteristics-corona-patients 

US Patient details:
https://www.kaggle.com/datasets/arashnic/covid19-case-surveillance-public-use-dataset 




