import psycopg2
import psycopg2.extensions
from config_database import *


class Database:
    def __init__(self, host, db_name, user, password):
        self.host = host
        self.db_name = db_name
        self.user = user
        self.password = password
        self.conn = None  # connection

    def connect(self):
        conn_string = "host='{0}' dbname='{1}' user='{2}' password='{3}'".format(self.host, self.db_name,
                                                                                 self.user, self.password)
        try:
            self.conn = psycopg2.connect(conn_string)
        except psycopg2.Error:
            print("Could not connect to database.")
        else:
            return True

    def disconnect(self):
        self.conn.close()

    def create_tables(self):

        author = "author (" \
                 "author_id SERIAL PRIMARY KEY, " \
                 "username TEXT NOT NULL UNIQUE, " \
                 "date_joined DATE NOT NULL, " \
                 "location TEXT, " \
                 "birthday DATE" \
                 ")"
        fandom = "fandom (" \
                 "fandom_id SERIAL PRIMARY KEY, " \
                 "name TEXT NOT NULL" \
                 ")"
        warning = "warning (" \
                  "warning_id SERIAL PRIMARY KEY, " \
                  "description TEXT NOT NULL" \
                  ")"
        category = "category (" \
                   "category_id SERIAL PRIMARY KEY, " \
                   "name TEXT NOT NULL" \
                   ")"
        character = "character (" \
                    "character_id SERIAL PRIMARY KEY, " \
                    "name TEXT NOT NULL UNIQUE" \
                    ")"
        story = "story (" \
                "story_id INTEGER PRIMARY KEY, " \
                "written_by INTEGER NOT NULL REFERENCES author(author_id), " \
                "title TEXT NOT NULL, " \
                "date_published DATE NOT NULL, " \
                "language TEXT NOT NULL, " \
                "summary TEXT NOT NULL, " \
                "completed BOOLEAN NOT NULL, " \
                "words INTEGER NOT NULL, " \
                "chapters INTEGER NOT NULL, " \
                "rating TEXT NOT NULL, " \
                "hits INTEGER NOT NULL, " \
                "kudos INTEGER NOT NULL, " \
                "comments INTEGER NOT NULL " \
                ")"

        contains_fandom = "contains_fandom(" \
                          "story INTEGER NOT NULL REFERENCES story(story_id), " \
                          "fandom INTEGER NOT NULL REFERENCES fandom(fandom_id) " \
                          ")"
        has_warning = "has_warning(" \
                      "story INTEGER NOT NULL REFERENCES story(story_id), " \
                      "warning INTEGER NOT NULL REFERENCES warning(warning_id) " \
                      ")"
        is_in_category = "is_in_category( " \
                         "story INTEGER NOT NULL REFERENCES story(story_id), " \
                         "category INTEGER NOT NULL REFERENCES category(category_id) " \
                         ")"
        contains_character = "contains_character(" \
                             "story INTEGER NOT NULL REFERENCES story(story_id), " \
                             "character INTEGER NOT NULL REFERENCES character(character_id)" \
                             ")"
        relationship = "relationship(" \
                       "person_1 INTEGER NOT NULL REFERENCES character(character_id), " \
                       "person_2 INTEGER NOT NULL REFERENCES character(character_id), " \
                       "PRIMARY KEY (person_1, person_2)" \
                       ")"
        contains_relationship = "contains_relationship(" \
                                "story INTEGER NOT NULL REFERENCES story(story_id)," \
                                "person_1 INTEGER," \
                                "person_2 INTEGER," \
                                "FOREIGN KEY (person_1, person_2) REFERENCES relationship(person_1, person_2)" \
                                ")"

        tables = [author, fandom, category, character, story, warning,
                  contains_fandom, has_warning, is_in_category, contains_character, relationship,
                  contains_relationship]

        cursor = self.conn.cursor()
        for table in tables:
            query = "CREATE TABLE IF NOT EXISTS " + table
            cursor.execute(query)
        self.conn.commit()
        cursor.close()

    def insert_story(self, story):
        cursor = self.conn.cursor()

        cursor.execute("SELECT author_id FROM author WHERE username = %s", [story['author'],])
        author = cursor.fetchone()

        query = "INSERT INTO story VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        cursor.executemany(query, [
            (story.get('story_id'),
             author,
             story.get('title'),
             story.get('date_published'),
             story.get('language'),
             story.get('summary'),
             story.get('completed'),
             story.get('words'),
             story.get('chapters'),
             story.get('rating'),
             story.get('hits'),
             story.get('kudos', 0),
             story.get('comments', 0)
             )
        ])

        self.conn.commit()
        cursor.close()


    def insert_character(self, character):
        cursor = self.conn.cursor()
        query = "INSERT INTO character VALUES (default, %s)"
        try:
            cursor.execute(query, character)
        except:
            pass
        self.conn.commit()
        cursor.close()


    def insert_author(self, author):
        cursor = self.conn.cursor()
        query = "INSERT INTO author VALUES (default, %s, %s, %s, %s)"
        try:
            cursor.executemany(query, [(author.get('username'), author.get('date_joined'), author.get('location'), author.get('birthday')),])
        except:
            pass
        self.conn.commit()
        cursor.close()


    def test(self):
        cursor = self.conn.cursor()
        cursor.execute("SELECT * FROM Cars")
        rows = cursor.fetchall()
        for row in rows:
            print(row)
        cursor.close()
