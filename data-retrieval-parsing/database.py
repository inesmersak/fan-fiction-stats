import psycopg2


class Database:
    def __init__(self, host, db_name, user, password):
        self.host = host
        self.db_name = db_name
        self.user = user
        self.password = password
        self.conn = None  # connection
        self.cur = None  # cursor

    def connect(self):
        conn_string = "host='{0}' dbname='{1}' user='{2}' password='{3}'".format(self.host, self.db_name,
                                                                                self.user, self.password)
        self.conn = psycopg2.connect(conn_string)
        self.cur = self.conn.cursor()

    def disconnect(self):
        self.cur.close()
        self.conn.close()
