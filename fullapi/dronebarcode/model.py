"""dronebarcode model (database) API."""
import sqlite3
import flask
import dronebarcode


def dict_factory(cursor, row):
    """Convert database row objects to a dictionary.

    Useful for building dictionaries which are then used to render a template.
    Note that this would be inefficient for large queries.
    """
    output = {}
    for idx, col in enumerate(cursor.description):
        output[col[0]] = row[idx]
    return output


def get_db():
    """Open a new database connection."""
    if not hasattr(flask.g, 'sqlite_db'):
        flask.g.sqlite_db = sqlite3.connect(
            dronebarcode.app.config['DATABASE_FILENAME'])
        flask.g.sqlite_db.row_factory = dict_factory

        # Foreign keys have to be enabled per-connection.  This is an sqlite3
        # backwards compatibility thing.
        flask.g.sqlite_db.execute("PRAGMA foreign_keys = ON")

    return flask.g.sqlite_db


def c_err(msg, code):
    """Construct an error message."""
    error = {}
    error["message"] = msg
    error["status_code"] = code
    return error


@dronebarcode.app.teardown_appcontext
def close_db(error):
    # pylint: disable=unused-argument
    """Close the database at the end of a request."""
    if hasattr(flask.g, 'sqlite_db'):
        flask.g.sqlite_db.commit()
        flask.g.sqlite_db.close()
