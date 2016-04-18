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
        # TODO
        pass

    def insert_story(self, story):
        # TODO
        pass

    def test(self):
        cursor = self.conn.cursor()
        cursor.execute("SELECT * FROM Cars")
        rows = cursor.fetchall()
        for row in rows:
            print(row)
        cursor.close()
