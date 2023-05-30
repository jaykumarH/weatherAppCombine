//
//  Publisher+Extension.swift
//  Weather
//
//  Created by Jaykumar on 2023-05-28.
//

import Foundation
import Combine

extension Publisher {
  func asResult() -> AnyPublisher<Result<Output, Failure>, Never> {
    self
      .map(Result.success)
      .catch { error in
        Just(.failure(error))
      }
      .eraseToAnyPublisher()
  }
}
