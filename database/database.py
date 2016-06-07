import psycopg2
import psycopg2.extensions
from psycopg2.extensions import AsIs
from data_retrieval_parsing import languages
import datetime


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
            self.conn.autocommit = True
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
                 "fandom_name TEXT NOT NULL UNIQUE" \
                 ")"
        warning = "warning (" \
                  "warning_id SERIAL PRIMARY KEY, " \
                  "warning_description TEXT NOT NULL UNIQUE" \
                  ")"
        category = "category (" \
                   "category_id SERIAL PRIMARY KEY, " \
                   "category_name TEXT NOT NULL UNIQUE" \
                   ")"
        character = "character (" \
                    "character_id SERIAL PRIMARY KEY, " \
                    "character_name TEXT NOT NULL UNIQUE" \
                    ")"
        story = "story (" \
                "story_id INTEGER PRIMARY KEY, " \
                "written_by INTEGER NOT NULL REFERENCES author(author_id), " \
                "title TEXT NOT NULL, " \
                "date_published DATE NOT NULL, " \
                "language INTEGER NOT NULL REFERENCES language(language_id), " \
                "summary TEXT, " \
                "completed BOOLEAN NOT NULL, " \
                "words INTEGER NOT NULL, " \
                "chapters INTEGER NOT NULL, " \
                "rating TEXT NOT NULL, " \
                "hits INTEGER NOT NULL, " \
                "kudos INTEGER NOT NULL, " \
                "comments INTEGER NOT NULL " \
                ")"

        language = "language (" \
                   "language_id SERIAL PRIMARY KEY, " \
                   "language_original TEXT NOT NULL UNIQUE, " \
                   "language_name TEXT NOT NULL UNIQUE" \
                   ")"

        contains_fandom = "contains_fandom(" \
                          "story INTEGER NOT NULL REFERENCES story(story_id), " \
                          "fandom INTEGER NOT NULL REFERENCES fandom(fandom_id)," \
                          "PRIMARY KEY (story, fandom) " \
                          ")"
        has_warning = "has_warning(" \
                      "story INTEGER NOT NULL REFERENCES story(story_id), " \
                      "warning INTEGER NOT NULL REFERENCES warning(warning_id)," \
                      "PRIMARY KEY (story, warning) " \
                      ")"
        is_in_category = "is_in_category( " \
                         "story INTEGER NOT NULL REFERENCES story(story_id), " \
                         "category INTEGER NOT NULL REFERENCES category(category_id), " \
                         "PRIMARY KEY (story, category) " \
                         ")"
        contains_character = "contains_character(" \
                             "story INTEGER NOT NULL REFERENCES story(story_id), " \
                             "character INTEGER NOT NULL REFERENCES character(character_id), " \
                             "PRIMARY KEY (story, character)" \
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
                                "FOREIGN KEY (person_1, person_2) REFERENCES relationship(person_1, person_2), " \
                                "PRIMARY KEY (story, person_1, person_2)" \
                                ")"

        tables = [author, fandom, category, character, language, story, warning,
                  contains_fandom, has_warning, is_in_category, contains_character, relationship,
                  contains_relationship]

        cursor = self.conn.cursor()
        for table in tables:
            query = "CREATE TABLE IF NOT EXISTS " + table
            cursor.execute(query)
        self.conn.commit()
        cursor.close()

        self.fill_categories()
        self.fill_warnings()
        self.fill_languages()

    def insert_story(self, story):
        f = open('type_errors.log', 'w', encoding='utf-8')
        g = open('internal_error.log', 'w', encoding='utf-8')
        h = open('integrity_error.log', 'w', encoding='utf-8')

        print(datetime.datetime, file=f, end="\n---------------------------------------\n")
        print(datetime.datetime, file=g, end="\n---------------------------------------\n")
        print(datetime.datetime, file=h, end="\n---------------------------------------\n")

        def insert_character(character):
            try:
                cursor.execute("INSERT INTO character VALUES (default, %s)", [character])
            except psycopg2.IntegrityError as e:
                self.conn.rollback()
                print("{0}".format(e), file=h)
            except psycopg2.InternalError as e:
                print("{0}".format(e), file=g)
                self.conn.rollback()
            else:
                self.conn.commit()


        def insert_contains_character(character):
            cursor.execute("SELECT character_id FROM character WHERE character_name = %s", [character])
            char_id = cursor.fetchone()[0]
            try:
                cursor.executemany("INSERT INTO contains_character VALUES (%s, %s)", [(story.get('story_id'), char_id),
                                                                                      ])
            except psycopg2.IntegrityError as e:
                self.conn.rollback()
                print("{0}".format(e), file=h)
            except psycopg2.InternalError as e:
                self.conn.rollback()
                print("{0}".format(e), file=g)
            else:
                self.conn.commit()

        def insert_relationship(relationship):
            if len(relationship) > 1:
                cursor.execute("SELECT character_id FROM character WHERE character_name = %s", [relationship[0]])
                id_0 = cursor.fetchone()[0]
                cursor.execute("SELECT character_id FROM character WHERE character_name = %s", [relationship[1]])
                id_1 = cursor.fetchone()[0]
                m, M = min(id_0, id_1), max(id_0, id_1)
                try:
                    cursor.executemany("INSERT INTO relationship VALUES (%s, %s)", [((m, M)), ])
                except psycopg2.IntegrityError as e:
                    self.conn.rollback()
                    #print("{0}".format(e), "integrity")
                except psycopg2.InternalError as e:
                    self.conn.rollback()
                    #print("{0}".format(e), "internal")
                else:
                    self.conn.commit()

        def insert_contains_relationship(relationship):
            if len(relationship) > 1:
                cursor.execute("SELECT character_id FROM character WHERE character_name = %s", [relationship[0]])
                id_0 = cursor.fetchone()[0]
                cursor.execute("SELECT character_id FROM character WHERE character_name = %s", [relationship[1]])
                id_1 = cursor.fetchone()[0]
                m, M = min(id_0, id_1), max(id_0, id_1)
                try:
                    cursor.executemany("INSERT INTO contains_relationship VALUES (%s, %s, %s)",
                                       [(story.get('story_id'), m, M), ])
                except psycopg2.IntegrityError as e:
                    self.conn.rollback()
                    print("{0}".format(e), file=h)
                except psycopg2.InternalError as e:
                    self.conn.rollback()
                    print("{0}".format(e), file=g)
                else:
                    self.conn.commit()

        def insert_is_in_category(cat):
            cursor.execute("SELECT category_id FROM category WHERE category_name = %s", [cat])
            category_data = cursor.fetchone()
            if category_data:
                cat_id = category_data[0]
                try:
                    cursor.executemany("INSERT INTO is_in_category VALUES (%s, %s)", [(story.get('story_id'), cat_id),
                                                                                      ])
                except psycopg2.IntegrityError as e:
                    self.conn.rollback()
                    print("{0}".format(e), file=h)
                except psycopg2.InternalError as e:
                    self.conn.rollback()
                    print("{0}".format(e), file=g)
                else:
                    self.conn.commit()

        def insert_has_warning(warn):
            cursor.execute("SELECT warning_id FROM warning WHERE warning_description = %s", [warn, ])
            warn_id = cursor.fetchone()[0]
            try:
                cursor.executemany("INSERT INTO has_warning VALUES (%s, %s)", [(story.get('story_id'), warn_id), ])
            except psycopg2.IntegrityError:
                self.conn.rollback()
            except psycopg2.InternalError:
                self.conn.rollback()
            else:
                self.conn.commit()

        def insert_fandom(fand):
            try:
                cursor.execute("INSERT INTO fandom VALUES (default, %s)", [fand, ])
            except psycopg2.IntegrityError:
                self.conn.rollback()
            except psycopg2.InternalError:
                self.conn.rollback()
            else:
                self.conn.commit()

        def insert_contains_fandom(fand):
            cursor.execute("SELECT fandom_id FROM fandom WHERE fandom_name = %s", [fand, ])
            fand_id = cursor.fetchone()[0]
            try:
                cursor.executemany("INSERT INTO contains_fandom VALUES (%s, %s)", [(story.get('story_id'), fand_id), ])
            except psycopg2.IntegrityError:
                self.conn.rollback()
            except psycopg2.InternalError:
                self.conn.rollback()
            else:
                self.conn.commit()

        def is_in_language(lang):
            cursor.execute("SELECT language_id FROM language WHERE language_original = %s", [lang, ])
            lang_id = cursor.fetchone()[0]
            try:
                cursor.executemany("INSERT INTO is_in_language VALUES (%s, %s)", [(story.get('story_id'), lang_id), ])
            except psycopg2.IntegrityError:
                self.conn.rollback()
            except psycopg2.InternalError:
                self.conn.rollback()
            else:
                self.conn.commit()

        # STORY
        cursor = self.conn.cursor()
        try:
            cursor.execute("SELECT author_id FROM author WHERE username = %s", [story.get('author')])
            author = cursor.fetchone()
        except psycopg2.InternalError as e:
            print("{0}".format(e), file=g)
            author = None
        try:
            cursor.execute("SELECT language_id FROM language WHERE language_name = %s", [story.get('language')])
            language = cursor.fetchone()
        except psycopg2.InternalError:
            language = None
        query = "INSERT INTO story VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        try:
            cursor.executemany(query, [
                (story.get('story_id'),
                 author,
                 story.get('title'),
                 story.get('date_published'),
                 language,
                 story.get('summary'),
                 story.get('completed'),
                 story.get('words'),
                 story.get('chapters'),
                 story.get('rating'),
                 story.get('hits', 0),
                 story.get('kudos', 0),
                 story.get('comments', 0)
                 )
            ])
        except psycopg2.DataError as e:
            print("{0}".format(e), file=f)
        except psycopg2.IntegrityError as e:
            print("{0}".format(e), file=h)
            self.conn.rollback()
        except psycopg2.InternalError as e:
            print("{0}".format(e), file=g)
            self.conn.rollback()
        else:
            self.conn.commit()

        # CHARACTERS and RELATIONSHIPS
        cast = set(story.get('characters'))
        for person in cast:
            insert_character(person)
            insert_contains_character(person)
        relationships = story.get('relationships')
        for ship in relationships:
            people = ship.split("/")
            for person in people:
                insert_character(person)
            insert_relationship(people)
            insert_contains_relationship(people)
        self.conn.commit()

        # CATEGORIES
        categories = story.get('categories')
        for category in categories:
            insert_is_in_category(category)

        # WARNINGS
        warnings = story.get('warnings')
        for warning in warnings:
            insert_has_warning(warning)

        # FANDOMS
        fandoms = story.get('fandoms')
        for fandom in fandoms:
            insert_fandom(fandom)
            insert_contains_fandom(fandom)

        cursor.close()
        f.close()
        g.close()
        h.close()

    def insert_author(self, author):
        cursor = self.conn.cursor()
        query = "INSERT INTO author VALUES (default, %s, %s, %s, %s)"
        try:
            cursor.executemany(query, [(author.get('username'),
                                        author.get('date_joined'),
                                        author.get('location'),
                                        author.get('birthday')),
                                       ])
        except psycopg2.IntegrityError as e:
            self.conn.rollback()
        except psycopg2.InternalError as e:
            print("Author Internal Error", e)
            self.conn.rollback()
        else:
            self.conn.commit()
        cursor.close()

    def fill_categories(self):
        cursor = self.conn.cursor()
        categories = ["M/M", "F/M", "Gen", "Multi", "F/F", "Other"]
        query = "INSERT INTO category VALUES (default, %s)"
        for x in categories:
            try:
                cursor.execute(query, [x])
            except psycopg2.IntegrityError:
                self.conn.rollback()
            except psycopg2.InternalError:
                self.conn.rollback()
            else:
                self.conn.commit()
        cursor.close()

    def fill_warnings(self):
        cursor = self.conn.cursor()
        warnings = ["No Archive Warnings Apply",
                    "Creator Chose Not To Use Archive Warnings",
                    "Major Character Death",
                    "Graphic Depictions Of Violence",
                    "Underage",
                    "Rape/Non-Con"]
        query = "INSERT INTO warning VALUES (default, %s)"
        for x in warnings:
            try:
                cursor.execute(query, [x, ])
            except psycopg2.IntegrityError:
                self.conn.rollback()
            except psycopg2.InternalError:
                self.conn.rollback()
            else:
                self.conn.commit()
        cursor.close()

    def fill_languages(self):
        cursor = self.conn.cursor()
        query = "INSERT INTO language VALUES (default, %s, %s)"
        for key in languages.language:
            try:
                self.execute = cursor.execute(query, [key, languages.language.get(key)])
            except psycopg2.IntegrityError:
                self.conn.rollback()
            except psycopg2.InternalError:
                self.conn.rollback()
            else:
                self.conn.commit()
        cursor.close()

    def story_exists(self, story):
        """Checks if the given story already exists in the database."""
        st_id = story.get('story_id')
        try:
            cursor = self.conn.cursor()
            cursor.execute("SELECT story_id FROM story WHERE story_id = %s", [st_id, ])
            story_id = cursor.fetchone()
        except psycopg2.InternalError:
            story_id = None
        cursor.close()
        if story_id:
            return True
        else:
            return False

    def author_exists(self, story):
        """Checks if the given story's author already exists in the database."""
        au_id = story.get('author')
        cursor = self.conn.cursor()
        try:
            cursor.execute("SELECT author_id FROM author WHERE username = %s", [au_id, ])
            author_id = cursor.fetchone()
        except psycopg2.InternalError as e:
            author_id = None
        cursor.close()
        if author_id:
            return True
        else:
            return False

    def grant_permissions(self, grantee=None):
        """
        Grants permissions to connect to the database and gives all privileges on all tables in public schema.
        :param grantee: The person to whom admin permissions are granted. If empty, view permissions are instead
        granted to the public account.
        :return:
        """
        cursor = self.conn.cursor()
        if not grantee:  # we are granting reading permission to the public account
            try:
                cursor.execute("GRANT CONNECT ON DATABASE %s TO javnost", [AsIs(self.db_name), ])
                cursor.execute("GRANT SELECT ON ALL TABLES IN SCHEMA public TO javnost")
            except psycopg2.InternalError as e:
                print(e)
        else:  # granting admin permissions to a user
            try:
                cursor.execute("GRANT ALL PRIVILEGES ON DATABASE %s TO %s", [AsIs(self.db_name), AsIs(grantee)])
                cursor.execute("GRANT ALL PRIVILEGES ON SCHEMA public TO %s", [AsIs(grantee), ])
                cursor.execute("GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO %s", [AsIs(grantee), ])
            except psycopg2.InternalError as e:
                print(e)
        cursor.close()

    def drop_all_tables(self):
        """
        Drops all tables if given the confirmation from user.
        :return: True if the tables were dropped, False otherwise.
        """
        confirmation = input("This will drop all tables. Are you sure you want to proceed? (y/n) ")
        if confirmation == "y":
            cursor = self.conn.cursor()
            try:
                cursor.execute("DROP SCHEMA public CASCADE")
                cursor.execute("CREATE SCHEMA public")
                cursor.execute("GRANT ALL ON SCHEMA public TO public")
            except psycopg2.InternalError as e:
                print(e)
            cursor.close()
            return True
        else:
            return False