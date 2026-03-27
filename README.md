Overview

This project focuses on building a clean and structured relational database based on raw Airbnb data: https://insideairbnb.com/get-the-data/

The main goal was to take messy and semi structured inputs and turn them into a consistent schema that actually makes sense from both technical and business perspective

Instead of just transforming data the focus was on making decisions about what should be kept, what should be simplified and what should be ignored

---

Key Objectives

clean and standardize raw Airbnb data  
design a relational model that is simple but scalable  
handle semi structured fields like amenities in a practical way  
ensure data consistency and logical correctness  
build a database that is ready to be used by analysts without additional heavy cleaning  

---

Architecture

Data is loaded from CSV files into a staging layer where the original structure is preserved

From there the data goes through cleaning and validation steps and is transformed into a relational model

The final result is a database with clear entities, relationships and constraints that reflect real world concepts instead of raw data dumps

---

Data Model

Core Tables

listings - main listing level data  
hosts - information about hosts  
reviews - aggregated review metrics  
reviews_detail - individual reviews  
availability - availability over different time windows  
location - geographical information  

---

Amenities Modeling

Amenities were the most problematic part of the dataset because they were stored as free text with a lot of noise and inconsistency

The same concept could appear in many different forms for example wifi speed descriptions brand names or device specifications

Instead of trying to manually clean everything a rule based approach was used

keywords were extracted from text  
amenities were mapped into a fixed set of categories  
non relevant data such as schedules or operational descriptions was intentionally excluded  

The goal was not to perfectly describe everything but to extract meaningful signal from messy data

---

Final Categories

wifi  
tv_entertainment  
audio  
kitchen  
appliances  
bathroom  
parking  
outdoor  
fitness  
wellness  
climate  
safety  
laundry_storage  
family  
gaming  
furniture  
services  

---

Data Cleaning Highlights

Amenities

classification based on keyword matching  
mapping brand names to actual meaning for example cosmetics to bathroom or audio brands to audio  
ignoring data that does not represent real amenities such as time schedules or availability notes  

Reviews

separation between aggregated data and detailed records  
validation of time based metrics  
basic sanity checks to catch inconsistent values  

Availability

validation of logical ranges for different time windows  
handling NULL values depending on context  
ensuring consistency between different availability columns  

---

Key Design Decisions

not all data belongs in one table or even in the same domain  
semi structured data should be simplified instead of over modeled  
some data is better ignored than forced into incorrect categories  
clarity and consistency are more important than building a perfect but complex model  

---

Technologies

PostgreSQL  
SQL for transformations and modeling  
CSV as data source  

---

Conclusion

This project is less about writing complex SQL and more about understanding the data and making the right decisions

The key challenge was not transforming data but deciding what the data actually represents and how it should be modeled

A big part of the work was recognizing that some fields mix multiple concepts and should be simplified instead of modeled in full detail

The final result is a clean and consistent database that reflects real entities and relationships and can be used without additional heavy preprocessing

This approach mirrors real data engineering work where the main value comes from structuring data in a way that makes it usable rather than just technically correct
