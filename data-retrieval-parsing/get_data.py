import requests
import re
import threading
import os


def get_pages(start, end, address):
    """
    Downloads the content from pages {start]-{end} and writes the content of the n-th page to 'pages/n.html'.
    :param start: First page to get.
    :param end: Last page to get.
    :param address: The address from which to get the content.
    """
    for page in range(start, end+1):
        parameters = {
            'page': page,
        }

        r2 = requests.get(address, params=parameters)
        with open('pages/{0}.html'.format(page), 'w', encoding='utf8') as output:
            output.write(r2.text)


def get_all_pages(pages_per_thread=10, start_number=1):
    """
    Gets all of the pages with results using threading.
    :param pages_per_thread: The number of pages one thread will download.
    :param start_number: First page to get.
    """
    directory = './pages'
    if not os.path.exists(directory):  # makes subdirectory pages, if it doesn't exist
        os.makedirs(directory)

    address = 'http://archiveofourown.org/tags/Harry%20Potter%20-%20J*d*%20K*d*%20Rowling/works?'

    r = requests.get(address)
    pages_pattern = re.compile(r'<li><a href=".*?">(\d*?)</a></li> <li class="next" title="next">')
    number_of_pages = int(pages_pattern.search(r.text).group(1))

    th = []
    for i in range(start_number, number_of_pages+1, pages_per_thread):
        th.append(threading.Thread(target=get_pages, args=(i, min(i+pages_per_thread, number_of_pages), address)))

    for thread in th:
        thread.start()
    for thread in th:
        thread.join()

if __name__ == "__main__":
    get_all_pages()
