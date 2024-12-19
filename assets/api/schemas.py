# api/schemas.py

from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class CountryBase(BaseModel):
    id: int
    country_name: str
    iso_code: str

    class Config:
        from_attributes = True

class TopicBase(BaseModel):
    id: int
    topic_name: str

    class Config:
        from_attributes = True

class LocationBase(BaseModel):
    latitude: Optional[float]
    longitude: Optional[float]
    country: Optional[str]
    city: Optional[str]

    class Config:
        from_attributes = True

class PublisherBase(BaseModel):
    id: int
    name: str
    location: Optional[LocationBase]

    class Config:
        from_attributes = True

class ArticleBase(BaseModel):
    id: int
    title: str
    link: str
    pub_date: Optional[datetime]
    publisher: Optional[PublisherBase]
    topic: Optional[TopicBase]

    class Config:
        from_attributes = True

class NewsListResponse(BaseModel):
    total: int
    page: int
    page_size: int
    items: List[ArticleBase]

class NewsDetailResponse(BaseModel):
    id: int
    title: str
    link: str
    pub_date: Optional[datetime]
    publisher: Optional[PublisherBase]
    topic: Optional[TopicBase]
    additional_info: Optional[dict]

class TopicListResponse(BaseModel):
    items: List[TopicBase]

class PublisherListResponse(BaseModel):
    items: List[PublisherBase]

class AutocompleteResponse(BaseModel):
    suggestions: List[str]
