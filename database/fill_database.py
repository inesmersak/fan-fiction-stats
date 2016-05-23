import threading
import math
from database import Database
from config_database import *
from data_retrieval_parsing import get_data
from data_retrieval_parsing import parse_data
import time
import datetime


def fill_database_in_range(start, end, address, db):
    """
    Fills the database with stories from pages {start}-{end}. This function is called in a thread.
    :param start: The first page to collect stories from.
    :param end: The last page to collect stories from.
    :param address: The address from which to collect HTML code.
    :param db: The database to insert stories into.
    """
    pages = get_data.get_pages(start, end, address)
    for page in pages:
        page_data = parse_data.parse_stories_from_page(page)
        for story in page_data:
            if not db.author_exists(story):
                author = parse_data.parse_user_data(story['author'], get_data.get_user_data(story['author']))
                db.insert_author(author)
            if not db.story_exists(story):
                db.insert_story(story)
            # db.insert_story(story)


def create_and_fill_database():
    """
    The main function to fill the database with stories. Creates multiple threads and calls the fill_database_in_range
    function in each thread.
    """
    t0 = time.time()
    db = Database(host, db_name, user, password)
    if db.connect():
        db.create_tables()
        address = 'http://archiveofourown.org/tags/Harry%20Potter%20-%20J*d*%20K*d*%20Rowling/works?'
        # address = 'http://archiveofourown.org/works/search?utf8=%E2%9C%93&work_search%5Bquery%5D=&work_search%5Btitle%5D=beyond+the+pale&work_search%5Bcreator%5D=ivyblossom&work_search%5Brevised_at%5D=&work_search%5Bcomplete%5D=0&work_search%5Bsingle_chapter%5D=0&work_search%5Bword_count%5D=&work_search%5Blanguage_id%5D=&work_search%5Bfandom_names%5D=&work_search%5Brating_ids%5D=&work_search%5Bcharacter_names%5D=&work_search%5Brelationship_names%5D=&work_search%5Bfreeform_names%5D=&work_search%5Bhits%5D=&work_search%5Bkudos_count%5D=&work_search%5Bcomments_count%5D=&work_search%5Bbookmarks_count%5D=&work_search%5Bsort_column%5D=&work_search%5Bsort_direction%5D=&commit=Search'
        # address = 'http://archiveofourown.org/works/search?utf8=%E2%9C%93&work_search%5Bquery%5D=&work_search%5Btitle%5D=When+Dark+Turns+to+Light&work_search%5Bcreator%5D=nerd4rice725&work_search%5Brevised_at%5D=&work_search%5Bcomplete%5D=0&work_search%5Bsingle_chapter%5D=0&work_search%5Bword_count%5D=&work_search%5Blanguage_id%5D=&work_search%5Bfandom_names%5D=&work_search%5Brating_ids%5D=&work_search%5Bcharacter_names%5D=&work_search%5Brelationship_names%5D=&work_search%5Bfreeform_names%5D=&work_search%5Bhits%5D=&work_search%5Bkudos_count%5D=&work_search%5Bcomments_count%5D=&work_search%5Bbookmarks_count%5D=&work_search%5Bsort_column%5D=&work_search%5Bsort_direction%5D=&commit=Search'

        number_of_pages = get_data.get_number_of_pages(address)
        #number_of_pages = 1
        start_number = number_of_pages - 40
        number_of_threads = 50
        pages_per_thread = int(math.ceil(number_of_pages/number_of_threads))

        th = []
        for i in range(start_number, number_of_pages + 1, pages_per_thread):
            th.append(threading.Thread(target=fill_database_in_range,
                                       args=(i, min(i + pages_per_thread - 1, number_of_pages), address, db)))

        for thread in th:
            thread.start()
        for thread in th:
            thread.join()

        db.disconnect()
    tk = time.time()
    print(datetime.timedelta(seconds=tk-t0))

if __name__ == "__main__":
    create_and_fill_database()
