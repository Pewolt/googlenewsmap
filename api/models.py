# models.py

from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

class Country(Base):
    __tablename__ = 'countries'
    id = Column(Integer, primary_key=True, index=True)
    country_name = Column(String, unique=True, index=True)
    iso_code = Column(String, unique=True, index=True)

    publishers = relationship("Publisher", back_populates="country")

class Topic(Base):
    __tablename__ = 'topics'
    id = Column(Integer, primary_key=True, index=True)
    topic_name = Column(String, unique=True, index=True)
    link = Column(String, unique=True, index=True)

class Publisher(Base):
    __tablename__ = 'publishers'
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    latitude = Column(Float)
    longitude = Column(Float)
    country_id = Column(Integer, ForeignKey('countries.id'))
    city = Column(String)

    country = relationship("Country", back_populates="publishers")
    articles = relationship("Article", back_populates="publisher")

class Feed(Base):
    __tablename__ = 'feeds'
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    language = Column(String)
    last_build_date = Column(DateTime)
    country_id = Column(Integer, ForeignKey('countries.id'))
    topic_id = Column(Integer, ForeignKey('topics.id'))
    query_params = Column(String)

    topic = relationship("Topic", back_populates="feeds")
    articles = relationship("Article", back_populates="feed")

class Article(Base):
    __tablename__ = 'articles'
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    link = Column(String, unique=True, index=True)
    pub_date = Column(DateTime)
    publisher_id = Column(Integer, ForeignKey('publishers.id'))
    feed_id = Column(Integer, ForeignKey('feeds.id'))

    publisher = relationship("Publisher", back_populates="articles")
    feed = relationship("Feed", back_populates="articles")
    topic = relationship("Topic", back_populates="articles")
