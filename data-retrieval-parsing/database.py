import psycopg2


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
        #TODO

        author = "author (author_id INTEGER PRIMARY KEY, location TEXT, birthday DATE, date_joined DATE NOT NULL)"
        fandom = "fandom (fandom_id INTEGER PRIMARY KEY, name TEXT NOT NULL)"
        warning = "warning (warning_id INTEGER PRIMARY KEY, description TEXT NOT NULL)"
        category = "category (category_id INTEGER PRIMARY KEY, name TEXT)"
        character = "character (character_id INTEGER PRIMARY KEY, name TEXT)"
        story = "story (story_id INTEGER PRIMARY KEY, completed BOOLEAN NOT NULL, word INTEGER NOT NULL, summary TEXT NOT NULL, rating TEXT NOT NULL, hits INTEGER NOT NULL, kudos INTEGER NOT NULL, title TEXT NOT NULL, language TEXT NOT NULL, chapters INTEGER NOT NULL, comments INTEGER NOT NULL)" 

        entities = [author, fandom, category, character, story]
        
        cur = self.conn.cursor()
        for entity in entities:
            ukaz = "CREATE TABLE IF NOT EXISTS " + entity
            cur.execute(ukaz)
        
        self.conn.commit()


        

    def insert_story(self, story):
        # TODO
        pass

    def lil_bobby(self, tekst):
        cur = self.conn.cursor()
        ukaz = "DROP TABLE " + tekst
        cur.execute(ukaz)
##        conn_string = "host='{0}' dbname='{1}' user='{2}' password='{3}'".format(self.host, self.db_name,
##                                                                                 self.user, self.password)
##        with psycopg2.connect(conn_string) as con:
##            cur = con.cursor()
##            ukaz = "DROP TABLE " + tekst
##            cur.execute(ukaz)
        cur.close()

    def test(self):
        cursor = self.conn.cursor()
        cursor.execute("SELECT * FROM Cars")
        rows = cursor.fetchall()
        for row in rows:
            print(row)
        cursor.close()


