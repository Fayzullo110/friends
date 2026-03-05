package com.friends.backend.common;

import java.util.List;

public class PagedResponse<T> {
  public List<T> items;
  public boolean hasMore;
  public Integer nextPage;
  public Integer nextOffset;

  public PagedResponse(List<T> items, boolean hasMore, Integer nextPage, Integer nextOffset) {
    this.items = items;
    this.hasMore = hasMore;
    this.nextPage = nextPage;
    this.nextOffset = nextOffset;
  }
}
