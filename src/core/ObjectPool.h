#pragma once

#include <functional>
#include <memory>
#include <vector>

template <typename T> class ObjectPool {
public:
  ObjectPool(size_t initialSize = 100) { Expand(initialSize); }

  template <typename... Args> T *Acquire(Args &&...args) {
    if (m_Pool.empty()) {
      Expand(m_Pool.capacity() > 0 ? m_Pool.capacity() * 2 : 100);
    }

    T *obj = m_Pool.back();
    m_Pool.pop_back();

    // In-place construct
    new (obj) T(std::forward<Args>(args)...);
    return obj;
  }

  void Release(T *obj) {
    if (!obj)
      return;
    obj->~T(); // Destruct
    m_Pool.push_back(obj);
  }

  void Shutdown() {
    // Since we allocated raw memory, we should free it.
    // But here we stored pointers to chunks.
    for (T *ptr : m_AllObjects) {
      ::operator delete(ptr);
    }
    m_Pool.clear();
    m_AllObjects.clear();
  }

private:
  void Expand(size_t count) {
    for (size_t i = 0; i < count; ++i) {
      // Allocate raw memory without constructing
      T *ptr = static_cast<T *>(::operator new(sizeof(T)));
      m_Pool.push_back(ptr);
      m_AllObjects.push_back(ptr);
    }
  }

  std::vector<T *> m_Pool;
  std::vector<T *> m_AllObjects;
};
