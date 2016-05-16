import requests
import re


def get_number_of_pages(address):
    """
    Retrieves the number of pages of results found at the address.
    :param address: The address from which to get the number of pages.
    :return: int number_of_pages
    """
    r = requests.get(address)
    pages_pattern = re.compile(r'<li><a href=".*?">(\d*?)</a></li> <li class="next" title="next">')
    number_of_pages = int(pages_pattern.search(r.text).group(1))
    return number_of_pages


def get_pages(start, end, address):
    """
    Downloads the content from pages {start]-{end} and stores the html of the page in the array pages.
    :param start: First page to get.
    :param end: Last page to get.
    :param address: The address from which to get the content.
    :return: pages
    """
    pages = []
    for page in range(start, end+1):
        parameters = {
            'page': page,
        }

        r2 = requests.get(address, params=parameters)
        pages.append(r2.text)
    return pages


def get_user_data(username):
    """
    Downloads the content of a user profile.
    :param username: The user whose profile to retrieve.
    :return: html of the user profile
    """
    address = 'http://archiveofourown.org/users/' + username + '/profile'
    r = requests.get(address)
    return r.text

