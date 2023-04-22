# Exploratory Data Analysis in SQL 


We are given information about the structure of the database in an **entity-relationship diagram** that shows the tables, their columns, and the relationships between the tables. There are six tables:
- The evanston311 table contains help requests sent to the city of Evanston, Illinois.
- The fortune500 table contains information on the 500 largest US companies by revenue from 2017.
- The stackoverflow contains data from the popular programming question and answer site. It includes daily counts of the number of questions that were tagged as being related to select technology companies.
- The company, tag_company, and tag_type are supporting tables with additional information related to the stackoverflow data.


In this analysis, we will be exploring the following related tables:
- 'stackoverflow': questions asked on Stack Overflow with certain tags.
- 'company': information on companies related to tags in 'stackoverflow'.
- 'tag_company': links 'stackoverflow' to 'company'.
- 'tag_type': type categories applied to tags in 'stackoverflow'.
- 'fortune500': information on top US companies.

![Entity relationship diagram with details of the different tables columns](https://user-images.githubusercontent.com/93951596/233757666-581fe546-fa60-4029-ba50-a788287558ba.png)
